package t::Net::BitTorrent::Protocol::BEP03::Metadata_single_file;
{
    use strict;
    use warnings;

    # Load standard modules
    use Module::Build;
    use Test::More;
    use Test::Moose;
    use Test::Exception;

    # Load local context
    BEGIN { -d '_build' ? last : chdir '..' for 1 .. 10 }
    my $t_builder = Test::More->builder;
    my $m_builder = Module::Build->current;

    # Load local modules
    BEGIN {
        require 't\10000_by_class\Net\BitTorrent\Protocol\BEP03\Metadata.t';
    }
    use parent-norequire, 't::Net::BitTorrent::Protocol::BEP03::Metadata';
    sub info_hash {'B7ADF9CE9C375F1F72CFCE1D989BED10502D551F'}

    sub meta_data {
        'd4:infod6:lengthi267e4:name11:credits.txt12:piece lengthi65536e6:pie'
            . 'ces20:lᓮȝ޵𠃽˟ٺԱxee';
    }

    sub init_args {
        my $s    = shift;
        my $args = $s->SUPER::init_args;
        $args->{'name'} = 'credits.txt';
        $args->{'pieces'}
            = pack('H*', '6ce193aec89ddeb5f0a083bd13cb9fd9bad4b178');
        $args;
    }
    sub files { [{length => 267, path => ['credits.txt']}] }

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
