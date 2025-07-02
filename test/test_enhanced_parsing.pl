#!/usr/bin/perl
use strict;
use warnings;

BEGIN {
    unshift @INC, '/workspaces/obs-build';
}

use Build::Rpm;
use Data::Dumper;

# Test the enhanced dependency parsing
my %config = ( 'debug' => 1 );

print "Testing enhanced dependency parsing with rpmspec integration:\n";
print "=" x 60 . "\n";

# Test with parse_dummy spec file
print "\n1. Testing parse_dummy.spec:\n";
my $result1 = Build::Rpm::parse(\%config, 'test/parse_dummy.spec');

print "Dependencies found:\n";
for my $dep (@{$result1->{'deps'} || []}) {
    print "  - $dep\n";
}

if ($result1->{'rpmspec_enhanced'}) {
    print "\n✅ Dependencies enhanced by rpmspec!\n";
    if ($result1->{'rpmspec_added_deps'}) {
        print "New dependencies added by rpmspec:\n";
        for my $dep (@{$result1->{'rpmspec_added_deps'}}) {
            print "  + $dep\n";
        }
    }
} else {
    print "\n⚠️  No rpmspec enhancement applied\n";
}

print "\n" . "=" x 60 . "\n";
print "✅ Testing completed!\n";
