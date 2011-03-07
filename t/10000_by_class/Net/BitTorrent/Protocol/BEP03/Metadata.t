package t::Net::BitTorrent::Protocol::BEP03::Metadata;
{
    use strict;
    use warnings;
    use lib 'lib';

    # Load standard modules
    use Module::Build;
    use Test::More;
    use parent 'Test::Class';
    use Test::Moose;
    use Test::Fatal;

    # Load local context
    BEGIN { -d '_build' ? last : chdir '..' for 1 .. 10 }
    my $t_builder = Test::More->builder;
    my $m_builder = Module::Build->current;

    # Load local modules
    BEGIN {
        require 't\10000_by_class\Net\BitTorrent\Protocol\BEP03\Storage.t';
    }
    use parent-norequire, 't::Net::BitTorrent::Protocol::BEP03::Storage';

    #
    sub class     {'Net::BitTorrent::Protocol::BEP03::Metadata'}
    sub info_hash {'859E525BD848DA81C1E67E127D308C9FB04B9742'}

    sub meta_data {
        'd4:infod5:filesld6:lengthi28229e4:pathl27:1291672777_30adc6a421_o.j'
            . 'pgeed6:lengthi21769e4:pathl27:2183742557_5c9a91727d_m.jpgeed6'
            . ':lengthi518e4:pathl10:credit.txteee4:name20:96020_miniswarm_s'
            . 'eed12:piece lengthi65536e6:pieces20:ހЋHJը/tT񁝾󞋯ee';
    }

    sub init_args {
        my $s    = shift;
        my $args = $s->SUPER::init_args;
        $args->{'name'}         = '96020_miniswarm_seed';
        $args->{'piece_length'} = 65536;
        $args->{'pieces'}
            = pack('H*', 'de807fd08b484ad5a82f7454f1819dbef39e8baf');
        $args;
    }

    sub files {
        my $s = shift;
        [    # coerced into proper objects
           {length => 28229,
            path   => ['1291672777_30adc6a421_o.jpg']
           },
           {length => 21769,
            path   => ['2183742557_5c9a91727d_m.jpg']
           },
           {length => 518, path => ['credit.txt']}
        ];
    }

    sub infohash : Test( 1 ) {
        my $s = shift;
        is $s->{'m'}->info_hash->to_Hex, $s->info_hash;
    }

    sub as_string : Test( 1 ) {
        my $s = shift;
        is $s->{'m'}->as_string, $s->meta_data;
    }

    sub class_can : Test( +1 ) {
        my $s = shift;
        $s->SUPER::class_can();
        can_ok $s->{'m'}, $_ for qw[as_string];
    }

    sub moose_does : Test( +0 ) {
        my $s = shift;
        $s->SUPER::moose_does();
    }

    sub moose_attributes : Test( +7 ) {
        my $s = shift;
        $s->SUPER::moose_attributes();
        has_attribute_ok $s->{'m'}, $_, 'has ' . $_
            for qw[files announce name pieces piece_length info_hash tracker];
    }

    sub method_002_write : Test( 2 ) {
        my $s = shift;
        is $s->{'m'}->write(0, 0, 'XXX'), 3,
            'wrote 3 bytes at index 0, offset 0';
        is $s->{'m'}->write(1, 0, 'XXX'), (),
            'fail to write 3 bytes at index 1, offset 0 (beyond end of storage)';
    }

    sub method_005_read : Test( 0 ) {
        my $s = shift;
    }

    #
    __PACKAGE__->runtests() if !caller;
}
1;

=pod

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

=head1 License and Legal

Copyright (C) 2008-2011 by Sanko Robinson <sanko@cpan.org>

This program is free software; you can redistribute it and/or modify it under
the terms of
L<The Artistic License 2.0|http://www.perlfoundation.org/artistic_license_2_0>.
See the F<LICENSE> file included with this distribution or
L<notes on the Artistic License 2.0|http://www.perlfoundation.org/artistic_2_0_notes>
for clarification.

When separated from the distribution, all original POD documentation is
covered by the
L<Creative Commons Attribution-Share Alike 3.0 License|http://creativecommons.org/licenses/by-sa/3.0/us/legalcode>.
See the
L<clarification of the CCA-SA3.0|http://creativecommons.org/licenses/by-sa/3.0/us/>.

Neither this module nor the L<Author|/Author> is affiliated with BitTorrent,
Inc.

=for rcs $Id$

=cut
