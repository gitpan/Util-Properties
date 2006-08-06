package Util::Properties;

#use warnings;
use strict;
use Carp qw(croak carp confess cluck);

=head1 NAME

Util::Properties - Java.util.properties like class

=head1 DESCRIPTION

rimplement something like ava.util.Properties API.

The main differences with CPAN existant Config::Properties and Data::Properties is file locking & autoload/autosave features

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

=begin text

use Util::Properties;

my $prop = Util::Properties->new({file=>'file.properties'});
my $xyz=$prop->prop_get('x.y.z');
$prop->prop_set('w', -1);
$prop->save();

=end text

=head1 FUNCTIONS

=head1 METHODS

=head2 Creators

=head3 my $prop=Util::Properties->new()

=head3 my $prop=Util::Properties->new(filename)

=head3 my $prop=Util::Properties->new(\%h)

=head3 my $prop=Util::Properties->new(\$Util::Properties)

Create a new prop system from either:

=over 4

=item empty

=item filename

=item hash ref (key=>values will be taken as property name/value)

=item a copy constructor from another Util::Properties object;

=back

=head2 Accessors/Mutators

=head3 $prop->name([$val])

Get/set a name for the set of prperty (mainly used for debugging or code clarity purpose

=head3 $prop->file_ismirrored([val])

Get/set (set if an argument is passed) a boolean value to determine if the file is to be file with property (if any is defined) is to be kept coherent with the data. This mean that any set of property will be mirrored on the file, and before any get, the file time stamp will be check to see if the data has changed into the file.

=head3 $prop->file_name([path])

Get/set the filename

=head3 $prop->file_md5([hexval])

Get/set the md5 of the file

=head3 $prop->file_locker(bool|\$LockFile::Simple);

Set if  a file locker is to be used (or a file locker is you do not wish to use the default). A die will be thrown if locking fails

=head3 $prop->file_locker();

Get the file locker (or undef).

=head3 $prop->file_isGhost([val])

get/set is it is possible for the file not to exist (in this case, no problem not to save...)

=head2 Properties values

=head3 $prop->prop_get(key)

get property defined by key;

=head3 $prop->prop_set(key, value)

Set a property

=head3 $prop->prop_list

return a hash with all the properties

=head3 $prop->prop_clean

Clean the properties list;

=head2 I/O

=head3 $prop->load()

load properties from $prop->file_name

=head3 $prop->save()

Save properties from $prop->file_name (comment have been forgotten)

=head1 EXPORT

=head3 $DEFAULT_FILE_LOCKER

If a file_locker is to be defined by default creator [default is 1]

=head3 $DEFAULT_FILE_ISMIRRORED

If data in memory must be consistent with file (based on file maodification time)  [default is 1]

=head3 $VERBOSE

verbose level;

=head1 AUTHOR

Alexandre Masselot, C<< <alexandre.masselot@genebio.com> >>

=head1 TODO

=head3 implement a '+=' notation (to have mult lines defined properties)

=begin text

prop.one=some
prop.one+=thing

=end text

=head3 implement a dependencies between properties

=begin text

prop.one=something
prop.two=other/${prop.one}-thing

=end text


=head1 BUGS

Please report any bugs or feature requests to
C<bug-util-properties@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Util-Properties>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Alexandre Masselot, all rights reserved.

This program is released under the following license: gpl

=cut

require Exporter;

our (@ISA, @EXPORT, @EXPORT_OK);
@ISA = qw(Exporter);

our $DEFAULT_FILE_LOCKER=1;
our $DEFAULT_FILE_ISMIRRORED=1;
our $VERBOSE=0;


@EXPORT = qw($DEFAULT_FILE_LOCKER $DEFAULT_FILE_ISMIRRORED $VERBOSE &new);
@EXPORT_OK = ();

use IO::All;
use Class::Std;

my %objref : ATTR;

sub BUILD{
  my ($selfref, $obj_ID, $h) = @_;
  #  my ($pkg, $h)=@_;

  my $self={};
  $objref{$obj_ID}=$self;

  if(ref($h)eq 'HASH'){
    if ($h->{properties}){    #just a set of properties
      $selfref->prop_clean;
      foreach (keys %{$h->{properties}}){
	$selfref->prop_set($_, $h->{properties}{$_});
      }
      $selfref->file_locker($DEFAULT_FILE_LOCKER);
      $selfref->file_ismirrored($DEFAULT_FILE_ISMIRRORED);
    }elsif($h->{copy}){
      my $src=$objref{ident($h->{copy})} || $h->{copy};
      #copy constructor
      $selfref->prop_clean;
      foreach my $k (keys %$src){
	if(ref ($src->{$k}) eq 'HASH'){
	  my $hh=$src->{$k};
	  $self->{$k}={}; #on se couvre if %$hh is empty;
	  foreach (keys %$hh){
	    $self->{$k}{$_}=$hh->{$_};
	  }
	}else{
	  $self->{$k}=$src->{$k};
	}
      }
    }elsif($h->{file}){
      #thus $h is a file name;
      $selfref->file_locker($DEFAULT_FILE_LOCKER);
      $selfref->file_ismirrored($DEFAULT_FILE_ISMIRRORED);
      $selfref->file_name($h->{file});
      $selfref->load();
    }elsif(scalar (keys %$h)){
      croak "cannot instanciate constructor if hahs key is not of (properties|copy|file)";
    }else{
      $selfref->file_locker($DEFAULT_FILE_LOCKER);
      $selfref->file_ismirrored($DEFAULT_FILE_ISMIRRORED);
      $selfref->prop_clean;
    }
  }else{
    die "empty BUILD constructor";
  }
  return $self;
}

our @attr=qw(name file_md5 file_name file_ismirrored file_isGhost);
our $attrStr=join '|', @attr;
our $attrRE=qr/\b($attrStr)\b/;

sub AUTOMETHOD{
  my ($self, $obj_ID, $val)=@_;
  my $set=exists $_[2];

  my $name=$_;
  return undef unless $name=~$attrRE;
  return sub {
    $objref{$obj_ID}{$name}=$val; return $val} if($set);
  return sub {return $objref{$obj_ID}{$name}};
}

sub DEMOLISH{
  my ($self, $obj_ID) = @_;
  delete $objref{$obj_ID};
}

sub file_locker{
  my $a0=shift;
  my $self=$objref{ident($a0)};
  my $val=shift;

  return $self->{file_locker}  unless($val);

  if(ref($val) eq 'LockFile::Simple'){
    $self->{file_locker}=$val;
  }else{
    require LockFile::Simple;
    $self->{file_locker} = LockFile::Simple->make(-format => '%f.lck',
						  -max => 20,
						  -delay => 1,
						  -nfs => 1,
						  -autoclean => 1
						 );
  }
  return $self->{file_locker};
}

############### properties

sub prop_set{
  my $self_id=shift;
  my $self=$objref{ident($self_id)};

  my ($k, $val)=@_;
  croak "must prop_set on a defined property key" unless $k;
  croak "cannot define a key=[$k]" if $k=~/[\s=]/;

  $self->{properties}{$k}=$val;
  if($self_id->file_ismirrored && $self_id->file_name){
    $self_id->save();
  }
}

sub prop_get{
  my $self_id=shift;
  my $self=$objref{ident($self_id)};

  my $k=shift or croak "must prop_get on a defined property key";
  if($self_id->file_ismirrored && $self_id->file_name && -f $self_id->file_name && ($self_id->file_md5()ne file_md5_hex($self_id->file_name))){
    warn "loading from [".$self_id->file_name."] because of file modified for  [$k]\n" if $VERBOSE >=1;
    $self_id->load();
  }
  return $self->{properties}{$k};
}

sub prop_list{
  my $self_id=shift;
  my $self=$objref{ident($self_id)};

  return %{$self->{properties}};
}

sub prop_clean{
  my $self_id=shift;
  my $self=$objref{ident($self_id)};

  $self->{properties}={};
}



############### I/O

use IO::All;
use Digest::MD5::File qw(file_md5_hex);

sub load{
  my $self_id=shift;
  my $self=$objref{ident($self_id)};


  my $fname=$self_id->file_name;
  croak "cannot read file [$fname]" unless -r $fname;

  eval{
    my $lockmgr=$self_id->file_locker;
    $lockmgr->trylock("$fname") || croak "can't lock [$fname]: $!\n" if $lockmgr;
    my @contents=io($fname)->slurp;
    $self_id->file_md5(file_md5_hex($fname));
    $lockmgr->unlock("$fname") || croak "can't unlock [$fname]: $!\n" if $lockmgr;

    $self_id->prop_clean;
    foreach(@contents){
      next if /^#/;
      next unless /^(\S+)\s*=\s*(.*?)\s*$/;
      $self->{properties}{$1}=$2;
    }
  };
  if($@){
    croak $@ unless $self_id->file_isGhost;
  }
}

sub save{
  my $self_id=shift;
  my $self=$objref{ident($self_id)};

  my $fname=$self_id->file_name;

  warn "saving to [$fname]\n" if $VERBOSE >=2;
  croak "cannot save file on undefined file" unless defined $fname;

  my $contents;
  my %h=%{$self->{properties}};
  foreach (sort keys %h){
    $contents.="$_=$h{$_}\n";
  }

  my $lockmgr=$self_id->file_locker;
  eval{
    $lockmgr->trylock("$fname") || croak "can't lock [$fname]: $!\n" if $lockmgr;
    $contents > io($fname);
    $self_id->file_md5(file_md5_hex($fname)) if $self_id->file_ismirrored;
    $lockmgr->unlock("$fname") || croak "can't unlock [$fname]: $!\n" if $lockmgr;
  };
  if($@){
    croak $@ unless $self_id->file_isGhost;
  }
}

use overload '""' => \&toSummaryString;

sub toSummaryString{
  my $self_id=shift;
  my $self=$objref{ident($self_id)};

  my $ret="prop_name=".($self_id->name or 'NO_NAME')."\t".$self_id->file_name."\n";
  my %h=$self_id->prop_list;
  foreach (sort keys %h){
    $ret.="\t$_\t$h{$_}\n";
  }
  return $ret;
}



return 1; # End of Util::Properties
