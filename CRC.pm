package Digest::CRC;

use strict;
use vars qw($VERSION @ISA @EXPORT_OK %_typedef);

require Exporter;

@ISA = qw(Exporter);

@EXPORT_OK = qw(
 crcccitt crc16 crc32 crc
);

$VERSION = '0.03';

%_typedef = (
# name,  [width,init,xorout,poly,refin,refout);
  crcccitt => [16,0xffff,0,0x1021,0,0],
  crc16 => [16,0,0,0x8005,1,1],
  crc32 => [32,0xffffffff,0xffffffff,0x04C11DB7,1,1],
);

sub new {
  my $that=shift;
  my %params=@_;
  my $class = ref($that) || $that;
  my $self = {map { ($_ => $params{$_}) }
                      qw(type width init xorout refin refout)};
  bless $self, $class;
  $self->reset();
  #use Data::Dumper; print Dumper $self;
  $self
}

sub reset {
  my $self = shift;
  my $typeparams;
  # default is crc32 if no type and no width is defined
  if (!defined($self->{type}) && !defined($self->{width})) {
    $self->{type} = "crc32";
  }
  if (defined($self->{type}) && exists($_typedef{$self->{type}})) {
    $typeparams = $_typedef{$self->{type}};
    $self->{width} = $typeparams->[0],
    $self->{init} = $typeparams->[1],
    $self->{xorout} = $typeparams->[2],
    $self->{poly} = $typeparams->[3],
    $self->{refin} = $typeparams->[4],
    $self->{refout} = $typeparams->[5],
  }
  $self->{_tab} = [_tabinit($self->{width}, $self->{poly}, $self->{refin})];
  delete $self->{_data};
  $self
}

#########################################
# Private init functions:

sub _tabinit {
  my ($width,$poly_in,$ref) = @_;
  my @crctab;
  my $poly = $poly_in;

  if ($ref) {
    my $p = $poly;
    $poly=0;
    for(my $i=1; $i < ($width+1); $i++) {
      $poly |= 1 << ($width-$i) if ($p & 1);
      $p=$p>>1;
    }
  }

  for (my $i=0; $i<256; $i++) {
    my $r = $i<<($width-8);
    $r = $i if $ref;
    for (my $j=0; $j<8; $j++) {
      if ($ref) {
	$r = ($r>>1)^($r&1&&$poly)
      } else {
	if ($r&(1<<($width-1))) {
	  $r = ($r<<1)^$poly
	} else {
	  $r = ($r<<1)
	}
      }
    }
    push @crctab, $r&2**$width-1;
  }
  @crctab;
}

#########################################
# Private output converter functions:
sub _encode_hex { unpack 'H*', $_[0] }
sub _encode_base64 {
	my $res;
	while ($_[0] =~ /(.{1,45})/gs) {
		$res .= substr pack('u', $1), 1;
		chop $res;
	}
	$res =~ tr|` -_|AA-Za-z0-9+/|;#`
	chop $res; chop $res;
	$res
}

#########################################
# OOP interface:

sub add {
  my $self = shift;
  $self->{_data} .= join '', @_ if @_;
  $self
}

sub addfile {
  my ($self,$fh) = @_;
  if (!ref($fh) && ref(\$fh) ne "GLOB") {
    require Symbol;
    $fh = Symbol::qualify($fh, scalar caller);
  }
  # $self->{_data} .= do{local$/;<$fh>};
  my $read = 0;
  my $buffer = '';
  $self->add($buffer) while $read = read $fh, $buffer, 8192;
  die __PACKAGE__, " read failed: $!" unless defined $read;
  $self
}

sub add_bits {
}

sub digest {
  my $self = shift;
  my $message = $self->{_data};
  my @tab = @{$self->{_tab}};
  my $crc = $self->{init};
  my $width = $self->{width};
  my $pos = -length $message;
  while ($pos) {
    if ($self->{refout}) {
      $crc = ($crc>>8)^$tab[($crc^ord(substr($message, $pos++, 1)))&0xff]
    } else {
      $crc = (($crc<<8)&0xffff)^$tab[(($crc>>($width-8))^ord(substr $message,$pos++,1))&0xff]
    }
  }
  $crc ^ $self->{xorout};
}

sub hexdigest {
  _encode_hex($_[0]->digest)
}

sub b64digest {
  _encode_base64($_[0]->digest)
}

sub clone {
  my $self = shift;
  my $clone = { 
    type => $self->{type},
    width => $self->{width},
    init => $self->{init},
    xorout => $self->{xorout},
    poly => $self->{poly},
    refin => $self->{refin},
    refout => $self->{refout}
  };
  bless $clone, ref $self || $self;
}

#########################################
# Procedural interface:

sub crc {
  my ($buffer, $width, $init, $xorout, $poly, $refin, $refout) = @_;
  my @tab = _tabinit($width,$poly,$refin);
  my $crc = $init;
  my $pos = -length $buffer;
  while ($pos) {
    if ($refout) {
      $crc = ($crc>>8)^$tab[($crc^ord(substr($buffer, $pos++, 1)))&0xff]
    } else {
      $crc = (($crc<<8)&0xffff)^$tab[(($crc>>($width-8))^ord(substr $buffer,$pos++,1))&0xff]
    }
  }
  $crc ^ $xorout;
}

# CRC-CCITT standard
# poly: 1021, width: 16, init: ffff, refin: no, refout: no, xorout: no

sub crcccitt {
  crc($_[0],16,0xffff,0,0x1021,0,0);
}


# CRC16
# poly: 8005, width: 16, init: 0000, revin: yes, revout: yes, xorout: no

sub crc16 {
  crc($_[0],16,0,0,0x8005,1,1);
}


# CRC32
# poly: 04C11DB7, width: 32, init: FFFFFFFF, revin: yes, revout: yes,
# xorout: FFFFFFFF
# equivalent to: cksum -o3

sub crc32 {
  crc($_[0],32,0xffffffff,0xffffffff,0x04C11DB7,1,1);
}

1;
__END__

=head1 NAME

Digest::CRC - Generic CRC functions

=head1 SYNOPSIS

  # Functional style

  use Digest::CRC qw(crc32 crc16 crcccitt crc);
  $crc = crc32("123456789");
  $crc = crc16("123456789");
  $crc = crcccitt("123456789");

  $crc = crc($input,$width,$init,$xorout,$poly,$refin,$refout);

  # OO style
  use Digest::CRC;

  $ctx = Digest::CRC->new(type=>"crc16");
  $ctx = Digest::CRC->new(width=>16, init=>0x0000, xorout=>0x0000, 
                          poly=>0x8005, refin=>1, refout=>1);

  $ctx->add($data);
  $ctx->addfile(*FILE);

  $digest = $ctx->digest;
  $digest = $ctx->hexdigest;
  $digest = $ctx->b64digest;


=head1 DESCRIPTION

The B<Digest::CRC> module calculates CRC sums of all sorts.
It contains wrapper functions with the correct parameters for CRC-CCITT,
CRC-16 and CRC-32.

=head1 AUTHOR

Oliver Maul, oli@42.nu

=head1 COPYRIGHT

CRC algorithm code taken from "A PAINLESS GUIDE TO CRC ERROR DETECTION
 ALGORITHMS".

The author of this package disclaims all copyrights and 
releases it into the public domain.

=cut
