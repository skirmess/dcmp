<skirmess> What's the correct way to die with a Unicode string from a module? I assume the correct way is to use
<skirmess> die encode('UTF-8', $str)
<skirmess> It's probably a bad idea to use
<skirmess> binmode(STDERR, ":utf8");
<skirmess> in a module as that turns it on for everyone?
<skirmess> I'm asking for something like
<skirmess> die encode('UTF-8', "Cannot read file $file: $!");
<skirmess> where $file could be a Unicode filename.
<ilmari> the exception should be text
<ilmari> i.e. a character string, not an encoded byte string
<ilmari> it's up to whoever displays the exception to correctly encode it
<skirmess> that means the script that uses this module should probaby call binmode on STDERR
<skirmess> makes sense
<skirmess> thanks
<albino> hi  all
<Grinnz> :encoding(UTF-8) or :utf8_strict (requires installing PerlIO::utf8_strict) would be better
<Grinnz> but yes
<skirmess> for binmode?
<Grinnz> correct
<Grinnz> also, make sure to check binmode for errors
<pink_mist> that's still up to the calling script though
<pink_mist> not really something his module should be doing
<Grinnz> yes, he already said that
* geospeck (~geospeck@2001:4640:662c:0:a8bf:59af:c215:ef1c) has joined
<lizmat> and another Perl 6 Weekly hits the Net: https://p6weekly.wordpress.com/2017/11/27/2017-48-community-first/
<skirmess> What's the correct way to sort file names? On Linux, file names are UTF-8 strings, which means you can have two files in the same directory that have the same Unicode file name, composed differently. What would you do if you would write ls in Perl?
<skirmess> Something like that?
<skirmess> sub _sorter {
<skirmess>     my $a_n = NFC($a);
<skirmess>     my $b_n = NFC($b);
<skirmess>     return $a_n eq $b_n ? $a cmp $b : $a_n cmp $b_n;
<skirmess> }
<skirmess> Or should I just use sort from Unicode::Collate?
<purl> Something like that is, like, totally possible
* geospeck has quit (Remote host closed the connection)
<pink_mist> I would just use Unicode::Collate, yeah
* lizmat has quit (Quit: Computer has gone to sleep.)
<Grinnz> this is how ls does it, which entirely ignores unicode and locales: https://metacpan.org/pod/Sort::filevercmp
<Grinnz> sorry, that's for ls -v
<Grinnz> to do it "correctly" i would decode the filenames (if you can assume they are all UTF-8 encoded) and then use locale; before sorting
<Grinnz> but i'm not sure if that accounts for composition and such
<skirmess> built in sort sorts them correctly if I "use locale"
* geospeck (~geospeck@2001:4640:662c:0:b0c2:db88:6432:3b3f) has joined
<skirmess> but not without "use locale". And the locale perldoc mentions that the default is "Native-platform/Unicode code point sort order"
<skirmess> which means I don't understand why I have to use locale
<hobbs> because you don't want unicode code point sort order
<skirmess> ahh
<Grinnz> without use locale, cmp ignores locale settings
<skirmess> yeah, I didn't pay attention to the "code point" part of the doc
<Grinnz> another fun fact about ls; it ignores non-alphanumeric characters when sorting filenames, which i emulate in Dir::ls
<Grinnz> https://metacpan.org/source/DBOOK/Dir-ls-0.004/lib/Dir/ls.pm#L93-98
<skirmess> I want to compare two directories, which means I have to sort all files to get a consistent order.
<Grinnz> if you're just sorting for consistency, codepoint sort seems sufficient
<Grinnz> and much less complicated
<hobbs> agreed
<hobbs> don't use locales for that :)
<skirmess> I also like changes to be printed in a sorted order
* jacoby has quit (Ping timeout: 360 seconds)
<skirmess> what's the price of using locales?
<Grinnz> lower performance, thread safety issues
<hobbs> different results on different machines, generally more complexity, speed
<Grinnz> yes and different results depending on the locale variables
<hobbs> btw, tangentially related (and cool in any case): https://stackoverflow.com/a/36659048/152948
<skirmess> "different results deoendong on the locale variable". isn't that a good thing?
<Grinnz> if that's what you're looking for, sure
<Grinnz> makes it harder to test, though
<skirmess> it's pain to test anyway because OS/X normalizes filenames on write. (thank you, Travis)
<skirmess> readdir might return a different UTF-8 string then what you used in open to write the file
<Grinnz> oh yes, filenames are their own portability pains
<mst> skirmess: APFS doesn't
<Grinnz> the big question though: do you want to consider two filenames which normalize to the same name, but exist as different byte sequences, to be considered the same in your module?
<Grinnz> as far as the filesystem is concerned, they are different filenames
<skirmess> i want to treat them as different
<skirmess> or, I want to consider them as what readdir returns.
<skirmess> does Unicode::Collate sorting use some kind of end user input (like the locale)?
<Grinnz> i don't believe it's locale dependent, it's specifically unicode collation
<Grinnz> with various customization options
<skirmess> but those are all options for the programmer, not end user?
<Grinnz> correct
