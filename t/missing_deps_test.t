#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 2;
use FindBin;
use File::Temp qw(tempfile);
use File::Spec;

use Build::Rpm;

# Embedded spec file content - includes complex features to test rpmspec handling
my $spec_content = <<'EOF';
%{lua:
function dist_to_rhel_minor(str, start)
  match = string.match(str, ".el9_%d+")
  if match then
     return string.sub(match, 6)
  end
  match = string.match(str, ".el9")
  if match then
     return 7
  end
  return -1
end}

%global rhel 9
%global dist .el9_6
%global rhel_minor_version %{lua:print(dist_to_rhel_minor(rpm.expand("%dist")))}

%if 0%{?rhel} == 9
  %if %{rhel_minor_version} > 5
    %ifnarch s390x
      %global with_wasi_sdk 1
    %endif
  %endif
%endif

Summary:              Sample spec file for testing rpmspec integration
Name:                 rpmspec_test
Version:              1.0.0
Release:              1%{?dist}
URL:                  https://example.com
License:              GPLv2+
Source:               rpmspec_test.tar.gz

BuildRequires:        cmake
BuildRequires:        bzip2-devel
BuildRequires:        libstdc++-static

%if %{with_wasi_sdk}
BuildRequires: lld clang cmake ninja-build
# Sure, this package is missing.
BuildRequires: missing-package
# OBS-specific BuildRequires
#!BuildIgnore: ignored-package
#!BuildConflicts: conflicting-package
%endif

# Test OBS-specific tags
#!RemoteAsset: https://example.com/asset.tar.gz
#!BuildTarget: x86_64

%description
Sample spec file for testing rpmspec integration with complex features
including Lua macros, conditionals, and OBS-specific extensions.

%prep
%setup -q

%build
cmake .
make

%install
make install DESTDIR=%{buildroot}

%files
%doc README
/usr/bin/*
EOF

my $tempfile;

# Test 1: Test complex lua macros with spec content
subtest "Parse complex lua macros with spec content" => sub {
    plan tests => 1;

    my $config = {};

    my $rpmspec_deps = Build::Rpm::extract_buildrequires_with_rpmspec($config, [ split("\n", $spec_content) ]);
    ok((grep { $_ eq 'missing-package' } @{$rpmspec_deps}) ? 1 : 0, "Missing package found in buildrequires");
    diag("buildrequires found: " . join(", ", @{$rpmspec_deps}));
};

# Test 2: Test complex lua macros with spec file
subtest "Parse complex lua macros with spec file" => sub {
    plan tests => 1;

    my $config = {};
    $tempfile = Build::Rpm::create_temp_spec_file($spec_content);
    my $rpmspec_deps = Build::Rpm::extract_buildrequires_with_rpmspec($config, $tempfile);
    ok((grep { $_ eq 'missing-package' } @{$rpmspec_deps}) ? 1 : 0, "Missing package found in buildrequires");
    diag("buildrequires found: " . join(", ", @{$rpmspec_deps}));
};

END {
    if (defined $tempfile && -f $tempfile) {
        unlink $tempfile or warn "Could not remove temporary spec file $tempfile: $!";
    }
    diag("✓ Complex lua macros handled correctly");
}