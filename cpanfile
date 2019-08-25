requires 'Cwd';
requires 'Digest::MD5';
requires 'File::Compare';
requires 'File::Spec';
requires 'constant', '1.01';
requires 'locale';
requires 'perl', '5.006';
requires 'strict';
requires 'warnings';

on configure => sub {
    requires 'ExtUtils::MakeMaker';
    requires 'perl', '5.006';
};

on test => sub {
    requires 'Capture::Tiny';
    requires 'Encode';
    requires 'FindBin';
    requires 'POSIX';
    requires 'Test::Builder';
    requires 'Test::Fatal';
    requires 'Test::MockModule';
    requires 'Test::More', '0.88';
    requires 'Test::TempDir::Tiny';
    requires 'lib';
    requires 'subs';
};

on develop => sub {
    requires 'CPANPLUS';
    requires 'FindBin';
    requires 'JSON::MaybeXS';
    requires 'Module::Info';
    requires 'Path::Tiny';
    requires 'Perl::Critic', '1.134';
    requires 'Perl::Critic::MergeProfile';
    requires 'Perl::Critic::Policy::Bangs::ProhibitDebuggingModules', '1.12';
    requires 'Perl::Critic::Policy::Bangs::ProhibitRefProtoOrProto', '1.12';
    requires 'Perl::Critic::Policy::Bangs::ProhibitUselessRegexModifiers', '1.12';
    requires 'Perl::Critic::Policy::BuiltinFunctions::ProhibitDeleteOnArrays', '0.02';
    requires 'Perl::Critic::Policy::BuiltinFunctions::ProhibitReturnOr', '0.01';
    requires 'Perl::Critic::Policy::CodeLayout::ProhibitFatCommaNewline', '96';
    requires 'Perl::Critic::Policy::CodeLayout::RequireFinalSemicolon', '96';
    requires 'Perl::Critic::Policy::CodeLayout::RequireTrailingCommaAtNewline', '96';
    requires 'Perl::Critic::Policy::Compatibility::ConstantLeadingUnderscore', '96';
    requires 'Perl::Critic::Policy::Compatibility::ConstantPragmaHash', '96';
    requires 'Perl::Critic::Policy::Compatibility::PerlMinimumVersionAndWhy', '96';
    requires 'Perl::Critic::Policy::Compatibility::ProhibitUnixDevNull', '96';
    requires 'Perl::Critic::Policy::Documentation::ProhibitAdjacentLinks', '96';
    requires 'Perl::Critic::Policy::Documentation::ProhibitBadAproposMarkup', '96';
    requires 'Perl::Critic::Policy::Documentation::ProhibitDuplicateHeadings', '96';
    requires 'Perl::Critic::Policy::Documentation::ProhibitLinkToSelf', '96';
    requires 'Perl::Critic::Policy::Documentation::ProhibitParagraphEndComma', '96';
    requires 'Perl::Critic::Policy::Documentation::ProhibitParagraphTwoDots', '96';
    requires 'Perl::Critic::Policy::Documentation::ProhibitUnbalancedParens', '96';
    requires 'Perl::Critic::Policy::Documentation::ProhibitVerbatimMarkup', '96';
    requires 'Perl::Critic::Policy::Documentation::RequireEndBeforeLastPod', '96';
    requires 'Perl::Critic::Policy::Documentation::RequireFilenameMarkup', '96';
    requires 'Perl::Critic::Policy::Documentation::RequireLinkedURLs', '96';
    requires 'Perl::Critic::Policy::Freenode::AmpersandSubCalls', '0.029';
    requires 'Perl::Critic::Policy::Freenode::ArrayAssignAref', '0.029';
    requires 'Perl::Critic::Policy::Freenode::BarewordFilehandles', '0.029';
    requires 'Perl::Critic::Policy::Freenode::ConditionalDeclarations', '0.029';
    requires 'Perl::Critic::Policy::Freenode::ConditionalImplicitReturn', '0.029';
    requires 'Perl::Critic::Policy::Freenode::DeprecatedFeatures', '0.029';
    requires 'Perl::Critic::Policy::Freenode::DiscouragedModules', '0.029';
    requires 'Perl::Critic::Policy::Freenode::Each', '0.029';
    requires 'Perl::Critic::Policy::Freenode::IndirectObjectNotation', '0.029';
    requires 'Perl::Critic::Policy::Freenode::LexicalForeachIterator', '0.029';
    requires 'Perl::Critic::Policy::Freenode::LoopOnHash', '0.029';
    requires 'Perl::Critic::Policy::Freenode::ModPerl', '0.029';
    requires 'Perl::Critic::Policy::Freenode::OpenArgs', '0.029';
    requires 'Perl::Critic::Policy::Freenode::OverloadOptions', '0.029';
    requires 'Perl::Critic::Policy::Freenode::POSIXImports', '0.029';
    requires 'Perl::Critic::Policy::Freenode::PackageMatchesFilename', '0.029';
    requires 'Perl::Critic::Policy::Freenode::PreferredAlternatives', '0.029';
    requires 'Perl::Critic::Policy::Freenode::StrictWarnings', '0.029';
    requires 'Perl::Critic::Policy::Freenode::Threads', '0.029';
    requires 'Perl::Critic::Policy::Freenode::Wantarray', '0.029';
    requires 'Perl::Critic::Policy::Freenode::WarningsSwitch', '0.029';
    requires 'Perl::Critic::Policy::Freenode::WhileDiamondDefaultAssignment', '0.029';
    requires 'Perl::Critic::Policy::HTTPCookies', '0.53';
    requires 'Perl::Critic::Policy::Lax::ProhibitComplexMappings::LinesNotStatements', '0.013';
    requires 'Perl::Critic::Policy::Modules::PerlMinimumVersion', '1.003';
    requires 'Perl::Critic::Policy::Modules::ProhibitModuleShebang', '96';
    requires 'Perl::Critic::Policy::Modules::ProhibitPOSIXimport', '96';
    requires 'Perl::Critic::Policy::Modules::ProhibitUseQuotedVersion', '96';
    requires 'Perl::Critic::Policy::Modules::RequirePerlVersion', '1.003';
    requires 'Perl::Critic::Policy::Moo::ProhibitMakeImmutable', '0.06';
    requires 'Perl::Critic::Policy::Moose::ProhibitDESTROYMethod', '1.05';
    requires 'Perl::Critic::Policy::Moose::ProhibitLazyBuild', '1.05';
    requires 'Perl::Critic::Policy::Moose::ProhibitMultipleWiths', '1.05';
    requires 'Perl::Critic::Policy::Moose::ProhibitNewMethod', '1.05';
    requires 'Perl::Critic::Policy::Moose::RequireCleanNamespace', '1.05';
    requires 'Perl::Critic::Policy::Moose::RequireMakeImmutable', '1.05';
    requires 'Perl::Critic::Policy::Perlsecret', 'v0.0.11';
    requires 'Perl::Critic::Policy::Subroutines::ProhibitExportingUndeclaredSubs', '0.05';
    requires 'Perl::Critic::Policy::Subroutines::ProhibitQualifiedSubDeclarations', '0.05';
    requires 'Perl::Critic::Policy::Tics::ProhibitManyArrows', '0.009';
    requires 'Perl::Critic::Policy::Tics::ProhibitUseBase', '0.009';
    requires 'Perl::Critic::Policy::TryTiny::RequireBlockTermination', '0.03';
    requires 'Perl::Critic::Policy::TryTiny::RequireUse', '0.05';
    requires 'Perl::Critic::Policy::ValuesAndExpressions::ConstantBeforeLt', '96';
    requires 'Perl::Critic::Policy::ValuesAndExpressions::NotWithCompare', '96';
    requires 'Perl::Critic::Policy::ValuesAndExpressions::PreventSQLInjection', 'v1.4.0';
    requires 'Perl::Critic::Policy::ValuesAndExpressions::ProhibitArrayAssignAref', '96';
    requires 'Perl::Critic::Policy::ValuesAndExpressions::ProhibitBarewordDoubleColon', '96';
    requires 'Perl::Critic::Policy::ValuesAndExpressions::ProhibitDuplicateHashKeys', '96';
    requires 'Perl::Critic::Policy::ValuesAndExpressions::ProhibitEmptyCommas', '96';
    requires 'Perl::Critic::Policy::ValuesAndExpressions::ProhibitNullStatements', '96';
    requires 'Perl::Critic::Policy::ValuesAndExpressions::ProhibitSingleArgArraySlice', '0.004';
    requires 'Perl::Critic::Policy::ValuesAndExpressions::RequireNumericVersion', '96';
    requires 'Perl::Critic::Policy::ValuesAndExpressions::UnexpandedSpecialLiteral', '96';
    requires 'Perl::Critic::Policy::Variables::ProhibitLoopOnHash', '0.008';
    requires 'Perl::Critic::Policy::Variables::ProhibitUnusedVarsStricter', '0.103';
    requires 'Perl::Critic::Policy::Variables::ProhibitUselessInitialization', '0.02';
    requires 'Pod::Wordlist';
    requires 'Test2::V0';
    requires 'Test::CPAN::Changes';
    requires 'Test::CPAN::Meta', '0.12';
    requires 'Test::CPAN::Meta::JSON';
    requires 'Test::CleanNamespaces';
    requires 'Test::DistManifest', '1.003';
    requires 'Test::EOL';
    requires 'Test::Kwalitee';
    requires 'Test::MinimumVersion', '0.008';
    requires 'Test::Mojibake';
    requires 'Test::More', '0.88';
    requires 'Test::NoTabs';
    requires 'Test::Perl::Critic::XTFiles';
    requires 'Test::PerlTidy::XTFiles';
    requires 'Test::Pod', '1.26';
    requires 'Test::Pod::LinkCheck';
    requires 'Test::Pod::Links', '0.003';
    requires 'Test::Portability::Files';
    requires 'Test::RequiredMinimumDependencyVersion', '0.003';
    requires 'Test::Spelling', '0.12';
    requires 'Test::Spelling::Comment', '0.005';
    requires 'Test::Version', '0.04';
    requires 'Test::XTFiles';
    requires 'XT::Files';
    requires 'XT::Util';
    requires 'lib';
};
feature 'dzil', 'Dist::Zilla' => sub {
on develop => sub {
        requires 'App::Prove';
        requires 'CHI';
        requires 'CPAN::Meta::Prereqs::Filter';
        requires 'CPAN::Meta::YAML';
        requires 'CPAN::Perl::Releases';
        requires 'Carp';
        requires 'Dist::Zilla';
        requires 'Dist::Zilla::File::InMemory';
        requires 'Dist::Zilla::File::OnDisk';
        requires 'Dist::Zilla::Plugin::AutoPrereqs';
        requires 'Dist::Zilla::Plugin::AutoPrereqs::Perl::Critic';
        requires 'Dist::Zilla::Plugin::CheckChangesHasContent';
        requires 'Dist::Zilla::Plugin::CheckIssues';
        requires 'Dist::Zilla::Plugin::CheckMetaResources';
        requires 'Dist::Zilla::Plugin::CheckPrereqsIndexed';
        requires 'Dist::Zilla::Plugin::CheckSelfDependency';
        requires 'Dist::Zilla::Plugin::CheckStrictVersion';
        requires 'Dist::Zilla::Plugin::ConfirmRelease';
        requires 'Dist::Zilla::Plugin::ExecDir';
        requires 'Dist::Zilla::Plugin::FinderCode';
        requires 'Dist::Zilla::Plugin::Git::CheckFor::CorrectBranch';
        requires 'Dist::Zilla::Plugin::Git::CheckFor::MergeConflicts';
        requires 'Dist::Zilla::Plugin::Git::Commit';
        requires 'Dist::Zilla::Plugin::Git::Contributors';
        requires 'Dist::Zilla::Plugin::Git::FilePermissions';
        requires 'Dist::Zilla::Plugin::Git::GatherDir', '2.016';
        requires 'Dist::Zilla::Plugin::Git::Push';
        requires 'Dist::Zilla::Plugin::Git::RequireUnixEOL';
        requires 'Dist::Zilla::Plugin::Git::Tag';
        requires 'Dist::Zilla::Plugin::GithubMeta';
        requires 'Dist::Zilla::Plugin::InstallGuide', '1.200007';
        requires 'Dist::Zilla::Plugin::License';
        requires 'Dist::Zilla::Plugin::MakeMaker';
        requires 'Dist::Zilla::Plugin::Manifest';
        requires 'Dist::Zilla::Plugin::ManifestSkip';
        requires 'Dist::Zilla::Plugin::MetaJSON';
        requires 'Dist::Zilla::Plugin::MetaNoIndex';
        requires 'Dist::Zilla::Plugin::MetaProvides::Package';
        requires 'Dist::Zilla::Plugin::MetaYAML';
        requires 'Dist::Zilla::Plugin::MinimumPerl', '1.006';
        requires 'Dist::Zilla::Plugin::NextRelease';
        requires 'Dist::Zilla::Plugin::PromptIfStale';
        requires 'Dist::Zilla::Plugin::PruneCruft';
        requires 'Dist::Zilla::Plugin::ReadmeAnyFromPod';
        requires 'Dist::Zilla::Plugin::ReversionOnRelease';
        requires 'Dist::Zilla::Plugin::ShareDir';
        requires 'Dist::Zilla::Plugin::TestRelease';
        requires 'Dist::Zilla::Plugin::UploadToCPAN';
        requires 'Dist::Zilla::Plugin::VerifyPhases';
        requires 'Dist::Zilla::Plugin::VersionFromMainModule';
        requires 'Dist::Zilla::Plugin::lib';
        requires 'Dist::Zilla::Role::AfterBuild';
        requires 'Dist::Zilla::Role::AfterRelease';
        requires 'Dist::Zilla::Role::BeforeBuild';
        requires 'Dist::Zilla::Role::BeforeRelease';
        requires 'Dist::Zilla::Role::FileFinderUser';
        requires 'Dist::Zilla::Role::FileGatherer';
        requires 'Dist::Zilla::Role::FileMunger';
        requires 'Dist::Zilla::Role::PluginBundle::Config::Slicer';
        requires 'Dist::Zilla::Role::PluginBundle::Easy';
        requires 'Dist::Zilla::Role::TestRunner';
        requires 'Dist::Zilla::Role::TextTemplate';
        requires 'Dist::Zilla::Types', '6.000';
        requires 'Dist::Zilla::Util';
        requires 'Dist::Zilla::Util::BundleInfo';
        requires 'Dist::Zilla::Util::CurrentCmd';
        requires 'Dist::Zilla::Util::ExpandINI::Reader';
        requires 'File::HomeDir';
        requires 'File::Temp';
        requires 'File::pushd';
        requires 'HTTP::Tiny';
        requires 'List::Util';
        requires 'Module::CPANfile', '1.1004';
        requires 'Module::Metadata';
        requires 'Moose', '0.99';
        requires 'Moose::Role';
        requires 'Scalar::Util';
        requires 'Term::ANSIColor';
        requires 'Text::Template';
        requires 'namespace::autoclean', '0.09';
        requires 'perl', '5.010';
        requires 'version', '0.77';
};
};
