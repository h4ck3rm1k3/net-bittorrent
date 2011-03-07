package Net::BitTorrent::Protocol::BEP03::Packets;
{
    use 5.010;
    use Moose::Role;
    use Moose::Util::TypeConstraints;
    our $MAJOR = 0; our $MINOR = 74; our $DEV = 14; our $VERSION = sprintf('%0d.%03d' . ($DEV ? (($DEV < 0 ? '' : '_') . '%03d') : ('')), $MAJOR, $MINOR, abs $DEV);
    use Carp qw[confess];
    use lib '../../../../../lib';
    use Net::BitTorrent::Protocol::BEP03::Types;
    use Net::BitTorrent::Protocol::BEP03::Bencode qw[:all];
    use vars qw[@EXPORT_OK %EXPORT_TAGS];
    use Exporter qw[];
    *import = *import = *Exporter::import;
    %EXPORT_TAGS = (
        build => [
            qw[ build_handshake build_keepalive build_choke build_unchoke
                build_interested build_not_interested build_have
                build_bitfield build_request build_piece build_cancel
                build_port]
        ],
        parse => [
            qw[ parse_packet _parse_handshake _parse_keepalive
                _parse_choke _parse_unchoke _parse_interested
                _parse_not_interested _parse_have _parse_bitfield
                _parse_request _parse_piece _parse_cancel _parse_port]
        ],
        types => [
            qw[ $HANDSHAKE $KEEPALIVE $CHOKE $UNCHOKE $INTERESTED
                $NOT_INTERESTED $HAVE $BITFIELD $REQUEST $PIECE $CANCEL $PORT]
        ]
    );
    @EXPORT_OK = sort map { @$_ = sort @$_; @$_ } values %EXPORT_TAGS;
    $EXPORT_TAGS{'all'} = \@EXPORT_OK;

    #
    our $HANDSHAKE      = -1;
    our $KEEPALIVE      = '';
    our $CHOKE          = 0;
    our $UNCHOKE        = 1;
    our $INTERESTED     = 2;
    our $NOT_INTERESTED = 3;
    our $HAVE           = 4;
    our $BITFIELD       = 5;
    our $REQUEST        = 6;
    our $PIECE          = 7;
    our $CANCEL         = 8;
    our $PORT           = 9;

    #
    sub build_handshake {
        my ($reserved, $infohash, $peerid) = @_;
        if ((!defined $reserved) || (length $reserved != 8)) {
            confess sprintf
                '%s::build_handshake() requires an 8 byte string for the reserved string',
                __PACKAGE__;
            return;
        }
        $infohash
            // confess sprintf '%s::build_handshake() requires an infohash',
            __PACKAGE__;
            #<<< perltidy will skip this
            state $info_hash_constraint //=
            #>>>
            Moose::Util::TypeConstraints::find_type_constraint(
               'Net::BitTorrent::Protocol::BEP03::Types::Metadata::Infohash');
        if ((!defined $peerid) || (length $peerid != 20)) {
            confess sprintf
                '%s::build_handshake() requires an 20 byte string for the peerid',
                __PACKAGE__;
            return;
        }
        return pack 'c/a* a8 H40 a20', 'BitTorrent protocol',
            $reserved, $info_hash_constraint->coerce($infohash)->to_Hex,
            $peerid;
    }
    sub build_keepalive      { pack 'N',  0 }
    sub build_choke          { pack 'Nc', 1, 0 }
    sub build_unchoke        { pack 'Nc', 1, 1 }
    sub build_interested     { pack 'Nc', 1, 2 }
    sub build_not_interested { pack 'Nc', 1, 3 }

    sub build_have {
        my ($index) = @_;
        if ((!defined $index) || ($index !~ m[^\d+$])) {
            confess sprintf
                '%s::build_have() requires an integer index parameter',
                __PACKAGE__;
            return;
        }
        pack 'NcN', 5, 4, $index;
    }

    sub build_bitfield {
        my ($bitfield) = @_;
        $bitfield // confess sprintf
            'Missing or undefined bitfield passed to %s::build_bitfield()',
            __PACKAGE__;
        $bitfield = pack 'B*', $bitfield->to_Bin if ref $bitfield;
        if ((!$bitfield) || (unpack('B*', $bitfield) !~ m[^[01]+$])) {
            confess sprintf
                'Malformed bitfield passed to %s::build_bitfield()',
                __PACKAGE__;
        }
        pack 'Nca*', (length($bitfield) + 1), 5, $bitfield;
    }

    sub build_request {
        my ($index, $offset, $length) = @_;
        if ((!defined $index) || ($index !~ m[^\d+$])) {
            confess sprintf
                '%s::build_request() requires an integer index parameter',
                __PACKAGE__;
            return;
        }
        if ((!defined $offset) || ($offset !~ m[^\d+$])) {
            confess sprintf
                '%s::build_request() requires an offset parameter',
                __PACKAGE__;
            return;
        }
        if ((!defined $length) || ($length !~ m[^\d+$])) {
            confess sprintf
                '%s::build_request() requires an length parameter',
                __PACKAGE__;
            return;
        }
        my $packed = pack('NNN', $index, $offset, $length);
        pack 'Nca*', length($packed) + 1, 6, $packed;
    }

    sub build_piece {
        my ($index, $offset, $length, $data) = @_;
        if ((!defined $index) || ($index !~ m[^\d+$])) {
            confess sprintf '%s::build_piece() requires an index parameter',
                __PACKAGE__;
            return;
        }
        if ((!defined $offset) || ($offset !~ m[^\d+$])) {
            confess sprintf '%s::build_piece() requires an offset parameter',
                __PACKAGE__;
            return;
        }
        if ((!defined $length) || ($length !~ m[^\d+$])) {
            confess sprintf '%s::build_piece() requires an length parameter',
                __PACKAGE__;
            return;
        }
        if (!$data or !$$data) {
            confess sprintf '%s::build_piece() requires data to work with',
                __PACKAGE__;
            return;
        }
        if ($length != length $$data) {
            confess sprintf
                'Incorrect data length or incomplete data block passed to %s::build_piece( %d, %d, %d, {%d bytes} )',
                __PACKAGE__, $index, $offset, $length, length $$data;
            return;
        }
        my $packed = pack('N2a*', $index, $offset, $$data);
        return pack('Nca*', length($packed) + 1, 7, $packed);
    }

    sub build_cancel {
        my ($index, $offset, $length) = @_;
        if ((!defined $index) || ($index !~ m[^\d+$])) {
            confess sprintf
                '%s::build_cancel() requires an integer index parameter',
                __PACKAGE__;
            return;
        }
        if ((!defined $offset) || ($offset !~ m[^\d+$])) {
            confess sprintf '%s::build_cancel() requires an offset parameter',
                __PACKAGE__;
            return;
        }
        if ((!defined $length) || ($length !~ m[^\d+$])) {
            confess sprintf '%s::build_cancel() requires an length parameter',
                __PACKAGE__;
            return;
        }
        my $packed = pack('N3', $index, $offset, $length);
        return pack('Nca*', length($packed) + 1, 8, $packed);
    }

    sub build_port {
        my ($port) = @_;
        if ((!defined $port) || ($port !~ m[^\d+$])) {
            confess sprintf '%s::build_port() requires an index parameter',
                __PACKAGE__;
            return;
        }
        return pack('NcN', length($port) + 1, 9, $port);
    }
    our %parse_packet_dispatch = ($KEEPALIVE      => \&_parse_keepalive,
                                  $CHOKE          => \&_parse_choke,
                                  $UNCHOKE        => \&_parse_unchoke,
                                  $INTERESTED     => \&_parse_interested,
                                  $NOT_INTERESTED => \&_parse_not_interested,
                                  $HAVE           => \&_parse_have,
                                  $BITFIELD       => \&_parse_bitfield,
                                  $REQUEST        => \&_parse_request,
                                  $PIECE          => \&_parse_piece,
                                  $CANCEL         => \&_parse_cancel,
                                  $PORT           => \&_parse_port
    );

    sub parse_packet {
        my ($data) = @_;
        if ((!$data) || (ref($data) ne 'SCALAR') || (!$$data)) {
            confess sprintf '%s::parse_packet() needs data to parse',
                __PACKAGE__;
            return;
        }
        my ($packet);
        if (unpack('c', $$data) == 0x13) {
            my @payload = _parse_handshake(substr($$data, 0, 68, ''));
            $packet = {type           => $HANDSHAKE,
                       packet_length  => 68,
                       payload_length => 48,
                       payload        => @payload
                }
                if @payload;
        }
        elsif (    (defined unpack('N', $$data))
               and (unpack('N', $$data) =~ m[\d]))
        {   if ((unpack('N', $$data) <= length($$data))) {
                (my ($packet_data), $$data) = unpack('N/aa*', $$data);
                my $packet_length = 4 + length $packet_data;
                (my ($type), $packet_data) = unpack('ca*', $packet_data);
                if (defined $parse_packet_dispatch{$type}) {
                    my $payload = $parse_packet_dispatch{$type}($packet_data);
                    $packet = {type          => $type,
                               packet_length => $packet_length,
                               (defined $payload
                                ? (payload        => $payload,
                                   payload_length => length $packet_data
                                    )
                                : (payload_length => 0)
                               ),
                    };
                }
                elsif (eval 'require Data::Dump') {
                    confess
                        sprintf
                        <<'END', Data::Dump::pp($type), Data::Dump::pp($packet);
Unhandled/Unknown packet where:
Type   = %s
Packet = %s
END
                }
            }
        }
        return $packet;
    }

    sub _parse_handshake {
        my ($packet) = @_;
        if (!$packet || (length($packet) < 68)) {

            #confess 'Not enough data for handshake packet';
            return;
        }
        my ($protocol_name, $reserved, $infohash, $peerid)
            = unpack('c/a a8 H40 a20', $packet);
        if ($protocol_name ne 'BitTorrent protocol') {

            #confess sprintf('Improper handshake; Bad protocol name (%s)',
            #             $protocol_name);
            return;
        }
        return [$reserved, $infohash, $peerid];
    }
    sub _parse_keepalive      { return; }
    sub _parse_choke          { return; }
    sub _parse_unchoke        { return; }
    sub _parse_interested     { return; }
    sub _parse_not_interested { return; }

    sub _parse_have {
        my ($packet) = @_;
        if ((!$packet) || (length($packet) < 1)) {
            confess 'Incorrect packet length for HAVE';
            return;
        }
        return unpack('N', $packet);
    }

    sub _parse_bitfield {
        my ($packet) = @_;
        if ((!$packet) || (length($packet) < 1)) {
            confess 'Incorrect packet length for BITFIELD';
            return;
        }
        return (pack 'b*', unpack 'B*', $packet);
    }

    sub _parse_request {
        my ($packet) = @_;
        if ((!$packet) || (length($packet) < 9)) {

            #confess
            #    sprintf(
            #         'Incorrect packet length for REQUEST (%d requires >=9)',
            #         length($packet || ''));
            return;
        }
        return ([unpack('N3', $packet)]);
    }

    sub _parse_piece {
        my ($packet) = @_;
        if ((!$packet) || (length($packet) < 9)) {

            #confess
            #    sprintf(
            #           'Incorrect packet length for PIECE (%d requires >=9)',
            #           length($packet || ''));
            return;
        }
        return ([unpack('N2a*', $packet)]);
    }

    sub _parse_cancel {
        my ($packet) = @_;
        if ((!$packet) || (length($packet) < 9)) {

            #confess
            #    sprintf(
            #          'Incorrect packet length for CANCEL (%d requires >=9)',
            #          length($packet || ''));
            return;
        }
        return ([unpack('N3', $packet)]);
    }

    sub _parse_port {
        my ($packet) = @_;
        if ((!$packet) || (length($packet) < 1)) {

            #confess 'Incorrect packet length for PORT';
            return;
        }
        return (unpack 'N', $packet);
    }
}
1;

=pod

=head1 NAME

Net::BitTorrent::Protocol::BEP03::Packets - Packet utilities for the BitTorrent protocol

=head1 Synopsis

    use Net::BitTorrent::Protocol qw[:build parse_packet];

    # Tell them what we want...
    my $handshake = build_handshake(
        pack('C*', split('', '00000000')),
        pack('H*', 'ddaa46b1ddbfd3564fca526d1b68420b6cd54201'),
        'your-peer-id-in-here'
    );

    # And the inverse...
    my ($reserved, $infohash, $peerid) = parse_packet( $handshake );

=head1 Description

What would BitTorrent be without packets? TCP noise, mostly.

For similar work and links to the specifications behind these packets,
move on down to the L<See Also|/"See Also"> section.

=head1 Exporting from Net::BitTorrent::Protocol

There are three tags available for import.  To get them all in one go,
use the C<:all> tag.

=over

=item C<:types>

Packet types

For more on what these packets actually mean, see the BitTorrent Spec.
This is a list of the currently supported packet types:

=over

=item HANDSHAKE

=item KEEPALIVE

=item CHOKE

=item UNCHOKE

=item INTERESTED

=item NOT_INTERESTED

=item HAVE

=item BITFIELD

=item REQUEST

=item PIECE

=item CANCEL

=item PORT

=back

=item C<:build>

These create packets ready-to-send to remote peers.  See
L<Building Functions|/"Building Functions">.

=item C<:parse>

These are used to parse unknown data into sensible packets.

=back

=head2 Building Functions

=over

=item C<build_handshake ( RESERVED, INFOHASH, PEERID )>

Creates an initial handshake packet.  All parameters must conform to
the BitTorrent spec:

=over

=item C<RESERVED>

...is the 8 byte string used to represent a client's capabilities for
extensions to the protocol.

=item C<INFOHASH>

...is the 20 byte SHA1 hash of the bencoded info from the metainfo
file.

=item C<PEERID>

...is 20 bytes.

=back

=item C<build_keepalive ( )>

Creates a keep-alive packet.  The keep-alive packet is zero bytes,
specified with the length prefix set to zero.  There is no message ID and
no payload.  Peers may close a connection if they receive no packets
(keep-alive or any other packet) for a certain period of time, so a keep-
alive packet must be sent to maintain the connection alive if no command
have been sent for a given amount of time.  This amount of time is
generally two minutes.

=item C<build_choke ( )>

Creates a choke packet.  The choke packet is fixed-length and has no
payload.

See Also: http://tinyurl.com/NB-docs-choking - Choking and Optimistic
Unchoking

=item C<build_unchoke ( )>

Creates an unchoke packet.  The unchoke packet is fixed-length and
has no payload.

See Also: http://tinyurl.com/NB-docs-choking - Choking and Optimistic
Unchoking

=item C<build_interested ( )>

Creates an interested packet.  The interested packet is fixed-length
and has no payload.

=item C<build_not_interested ( )>

Creates a not interested packet.  The not interested packet is
fixed-length and has no payload.

=item C<build_have ( INDEX )>

Creates a have packet.  The have packet is fixed length.  The
payload is the zero-based INDEX of a piece that has just been
successfully downloaded and verified via the hash.

I<That is the strict definition, in reality some games may be played.
In particular because peers are extremely unlikely to download pieces
that they already have, a peer may choose not to advertise having a
piece to a peer that already has that piece.  At a minimum "HAVE
suppression" will result in a 50% reduction in the number of HAVE
packets, this translates to around a 25-35% reduction in protocol
overhead. At the same time, it may be worthwhile to send a HAVE
packet to a peer that has that piece already since it will be useful
in determining which piece is rare.>

I<A malicious peer might also choose to advertise having pieces that
it knows the peer will never download. Due to this attempting to model
peers using this information is a bad idea.>

=item C<build_bitfield ( BITFIELD )>

Creates a bitfield packet.  The bitfield packet is variable length,
where C<X> is the length of the C<BITFIELD>.  The payload is a
C<BITFIELD> representing the pieces that have been successfully
downloaded.  The high bit in the first byte corresponds to piece index
0.  Bits that are cleared indicated a missing piece, and set bits
indicate a valid and available piece. Spare bits at the end are set to
zero.

A bitfield packet may only be sent immediately after the
L<handshaking|/"build_handshake ( RESERVED, INFOHASH, PEERID )">
sequence is completed, and before any other packets are sent.  It is
optional, and need not be sent if a client has no pieces or uses one
of the Fast Extension packets: L<have all|/"build_have_all ( )"> or
L<have none|/"build_have_none ( )">.

=begin :parser

I<A bitfield of the wrong length is considered an error.  Clients
should drop the connection if they receive bitfields that are not of
the correct size, or if the bitfield has any of the spare bits set.>

=end :parser

=item C<build_request ( INDEX, OFFSET, LENGTH )>

Creates a request packet.  The request packet is fixed length, and
is used to request a block.  The payload contains the following
information:

=over

=item C<INDEX>

...is an integer specifying the zero-based piece index.

=item C<OFFSET>

...is an integer specifying the zero-based byte offset within the
piece.

=item C<LENGTH>

...is an integer specifying the requested length.

=back

See Also: L<build_cancel|/"build_cancel ( INDEX, OFFSET, LENGTH )">

=item C<build_piece ( INDEX, OFFSET, DATA )>

Creates a piece packet.  The piece packet is variable length, where
C<X> is the length of the L<DATA>.  The payload contains the following
information:

=over

=item C<INDEX>

...is an integer specifying the zero-based piece index.

=item C<OFFSET>

...is an integer specifying the zero-based byte offset within the
piece.

=item C<DATA>

...is the block of data, which is a subset of the piece specified by
C<INDEX>.

=back

Before sending pieces to remote peers, the client should verify that
the piece matches the SHA1 hash related to it in the .torrent
metainfo.

=item C<build_cancel ( INDEX, OFFSET, LENGTH )>

Creates a cancel packet.  The cancel packet is fixed length, and is
used to cancel
L<block requests|/"build_request ( INDEX, OFFSET, LENGTH )">.  The
payload is identical to that of the
L<request|/"build_request ( INDEX, OFFSET, LENGTH )"> packet.  It is
typically used during 'End Game.'

See Also: http://tinyurl.com/NB-docs-EndGame - End Game

=item C<build_extended ( DATA )>

Creates an extended protocol packet.

=back

=head3 Legacy Packets

The following packets are either part of the base protocol or one of
the common extensions but have either been superseded or simply
removed from the majority of clients.  I have provided them here only
for legacy support; they will not be removed in the future.

=over

=item C<build_port ( PORT )>

Creates a port packet.

See also: http://bittorrent.org/beps/bep_0003.html - The BitTorrent
Protocol Specification

=back

=head2 Parsing Function(s)

=over

=item C<parse_packet( DATA )>

Attempts to parse any known packet from the data (a scalar ref) passed to it.
On success, the payload and type are returned and the packet is removed from
the incoming data ref.  C<undef> is returned on failure.

=back

=head1 See Also

L<http://bittorrent.org/beps/bep_0003.html|http://bittorrent.org/beps/bep_0003.html>
- The BitTorrent Protocol Specification

L<Net::BitTorrent::Protocol::BEP06::Packets|Net::BitTorrent::BEP06::Packets> -
Fast Extension Packets

L<Net::BitTorrent::Protocol::BEP10::Packets|Net::BitTorrent::BEP10::Packets>
- Extension Protocol Packets

L<http://wiki.theory.org/BitTorrentSpecification|http://wiki.theory.org/BitTorrentSpecification>
- An annotated guide to the BitTorrent protocol

L<Net::BitTorrent::PeerPacket|Net::BitTorrent::PeerPacket|Net::BitTorrent::PeerPacket|Net::BitTorrent::PeerPacket>
- by Joshua McAdams

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
