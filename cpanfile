requires "Cwd" => "0";
requires "perl" => "5.006";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "File::Spec" => "0";
  requires "Test::Fatal" => "0";
  requires "Test::More" => "0.88";
  requires "Test::TempDir::Tiny" => "0";
  requires "autodie" => "0";
  requires "lib" => "0";
  requires "perl" => "5.006";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "perl" => "5.006";
};

on 'develop' => sub {
  requires "File::Spec" => "0";
  requires "Perl::Critic" => "1.130";
  requires "Perl::Critic::Policy::Bangs::ProhibitBitwiseOperators" => "1.12";
  requires "Perl::Critic::Policy::Bangs::ProhibitDebuggingModules" => "1.12";
  requires "Perl::Critic::Policy::Bangs::ProhibitFlagComments" => "1.12";
  requires "Perl::Critic::Policy::Bangs::ProhibitNumberedNames" => "1.12";
  requires "Perl::Critic::Policy::Bangs::ProhibitRefProtoOrProto" => "1.12";
  requires "Perl::Critic::Policy::Bangs::ProhibitUselessRegexModifiers" => "1.12";
  requires "Perl::Critic::Policy::BuiltinFunctions::ProhibitDeleteOnArrays" => "0.02";
  requires "Perl::Critic::Policy::BuiltinFunctions::ProhibitReturnOr" => "0.01";
  requires "Perl::Critic::Policy::CodeLayout::ProhibitFatCommaNewline" => "95";
  requires "Perl::Critic::Policy::CodeLayout::RequireFinalSemicolon" => "95";
  requires "Perl::Critic::Policy::CodeLayout::RequireTrailingCommaAtNewline" => "95";
  requires "Perl::Critic::Policy::Compatibility::ConstantLeadingUnderscore" => "95";
  requires "Perl::Critic::Policy::Compatibility::ConstantPragmaHash" => "95";
  requires "Perl::Critic::Policy::Compatibility::PerlMinimumVersionAndWhy" => "95";
  requires "Perl::Critic::Policy::Compatibility::ProhibitUnixDevNull" => "95";
  requires "Perl::Critic::Policy::Documentation::ProhibitAdjacentLinks" => "95";
  requires "Perl::Critic::Policy::Documentation::ProhibitBadAproposMarkup" => "95";
  requires "Perl::Critic::Policy::Documentation::ProhibitDuplicateHeadings" => "95";
  requires "Perl::Critic::Policy::Documentation::ProhibitLinkToSelf" => "95";
  requires "Perl::Critic::Policy::Documentation::ProhibitParagraphEndComma" => "95";
  requires "Perl::Critic::Policy::Documentation::ProhibitParagraphTwoDots" => "95";
  requires "Perl::Critic::Policy::Documentation::ProhibitUnbalancedParens" => "95";
  requires "Perl::Critic::Policy::Documentation::ProhibitVerbatimMarkup" => "95";
  requires "Perl::Critic::Policy::Documentation::RequireEndBeforeLastPod" => "95";
  requires "Perl::Critic::Policy::Documentation::RequireFilenameMarkup" => "95";
  requires "Perl::Critic::Policy::Documentation::RequireLinkedURLs" => "95";
  requires "Perl::Critic::Policy::Freenode::AmpersandSubCalls" => "0.024";
  requires "Perl::Critic::Policy::Freenode::ArrayAssignAref" => "0.024";
  requires "Perl::Critic::Policy::Freenode::BarewordFilehandles" => "0.024";
  requires "Perl::Critic::Policy::Freenode::ConditionalDeclarations" => "0.024";
  requires "Perl::Critic::Policy::Freenode::ConditionalImplicitReturn" => "0.024";
  requires "Perl::Critic::Policy::Freenode::DeprecatedFeatures" => "0.024";
  requires "Perl::Critic::Policy::Freenode::DiscouragedModules" => "0.024";
  requires "Perl::Critic::Policy::Freenode::DollarAB" => "0.024";
  requires "Perl::Critic::Policy::Freenode::Each" => "0.024";
  requires "Perl::Critic::Policy::Freenode::IndirectObjectNotation" => "0.024";
  requires "Perl::Critic::Policy::Freenode::ModPerl" => "0.024";
  requires "Perl::Critic::Policy::Freenode::OpenArgs" => "0.024";
  requires "Perl::Critic::Policy::Freenode::OverloadOptions" => "0.024";
  requires "Perl::Critic::Policy::Freenode::POSIXImports" => "0.024";
  requires "Perl::Critic::Policy::Freenode::PackageMatchesFilename" => "0.024";
  requires "Perl::Critic::Policy::Freenode::Prototypes" => "0.024";
  requires "Perl::Critic::Policy::Freenode::StrictWarnings" => "0.024";
  requires "Perl::Critic::Policy::Freenode::Threads" => "0.024";
  requires "Perl::Critic::Policy::Freenode::Wantarray" => "0.024";
  requires "Perl::Critic::Policy::Freenode::WarningsSwitch" => "0.024";
  requires "Perl::Critic::Policy::Freenode::WhileDiamondDefaultAssignment" => "0.024";
  requires "Perl::Critic::Policy::HTTPCookies" => "0.53";
  requires "Perl::Critic::Policy::Lax::ProhibitComplexMappings::LinesNotStatements" => "0.013";
  requires "Perl::Critic::Policy::Modules::PerlMinimumVersion" => "1.003";
  requires "Perl::Critic::Policy::Modules::ProhibitModuleShebang" => "95";
  requires "Perl::Critic::Policy::Modules::ProhibitPOSIXimport" => "95";
  requires "Perl::Critic::Policy::Modules::ProhibitUseQuotedVersion" => "95";
  requires "Perl::Critic::Policy::Modules::RequirePerlVersion" => "1.003";
  requires "Perl::Critic::Policy::Moo::ProhibitMakeImmutable" => "0.01";
  requires "Perl::Critic::Policy::Moose::ProhibitDESTROYMethod" => "1.05";
  requires "Perl::Critic::Policy::Moose::ProhibitLazyBuild" => "1.05";
  requires "Perl::Critic::Policy::Moose::ProhibitMultipleWiths" => "1.05";
  requires "Perl::Critic::Policy::Moose::ProhibitNewMethod" => "1.05";
  requires "Perl::Critic::Policy::Moose::RequireCleanNamespace" => "1.05";
  requires "Perl::Critic::Policy::Moose::RequireMakeImmutable" => "1.05";
  requires "Perl::Critic::Policy::Perlsecret" => "v0.0.11";
  requires "Perl::Critic::Policy::Subroutines::ProhibitExportingUndeclaredSubs" => "0.05";
  requires "Perl::Critic::Policy::Subroutines::ProhibitQualifiedSubDeclarations" => "0.05";
  requires "Perl::Critic::Policy::Tics::ProhibitManyArrows" => "0.009";
  requires "Perl::Critic::Policy::Tics::ProhibitUseBase" => "0.009";
  requires "Perl::Critic::Policy::TryTiny::RequireBlockTermination" => "0.01";
  requires "Perl::Critic::Policy::TryTiny::RequireUse" => "0.02";
  requires "Perl::Critic::Policy::ValuesAndExpressions::ConstantBeforeLt" => "95";
  requires "Perl::Critic::Policy::ValuesAndExpressions::NotWithCompare" => "95";
  requires "Perl::Critic::Policy::ValuesAndExpressions::PreventSQLInjection" => "v1.4.0";
  requires "Perl::Critic::Policy::ValuesAndExpressions::ProhibitArrayAssignAref" => "95";
  requires "Perl::Critic::Policy::ValuesAndExpressions::ProhibitBarewordDoubleColon" => "95";
  requires "Perl::Critic::Policy::ValuesAndExpressions::ProhibitDuplicateHashKeys" => "95";
  requires "Perl::Critic::Policy::ValuesAndExpressions::ProhibitEmptyCommas" => "95";
  requires "Perl::Critic::Policy::ValuesAndExpressions::ProhibitNullStatements" => "95";
  requires "Perl::Critic::Policy::ValuesAndExpressions::ProhibitUnknownBackslash" => "95";
  requires "Perl::Critic::Policy::ValuesAndExpressions::RequireNumericVersion" => "95";
  requires "Perl::Critic::Policy::ValuesAndExpressions::UnexpandedSpecialLiteral" => "95";
  requires "Perl::Critic::Policy::Variables::ProhibitUnusedVarsStricter" => "0.100";
  requires "Perl::Critic::Policy::Variables::ProhibitUselessInitialization" => "0.02";
  requires "Perl::Critic::Utils" => "0";
  requires "Pod::Wordlist" => "0";
  requires "Test::CPAN::Changes" => "0";
  requires "Test::CPAN::Meta" => "0.12";
  requires "Test::CPAN::Meta::JSON" => "0";
  requires "Test::CleanNamespaces" => "0";
  requires "Test::DistManifest" => "1.003";
  requires "Test::EOL" => "0";
  requires "Test::Kwalitee" => "0";
  requires "Test::MinimumVersion" => "0.008";
  requires "Test::Mojibake" => "0";
  requires "Test::More" => "0.88";
  requires "Test::NoTabs" => "0";
  requires "Test::Perl::Critic" => "0";
  requires "Test::Pod" => "1.26";
  requires "Test::Pod::No404s" => "0";
  requires "Test::Portability::Files" => "0";
  requires "Test::Spelling" => "0.12";
  requires "Test::Version" => "0.04";
};
