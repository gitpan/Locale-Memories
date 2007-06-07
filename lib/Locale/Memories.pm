package Locale::Memories;

use strict;
use utf8;
use Data::Dumper;
use Search::Xapian qw(:ops);

our $VERSION = '0.03';

sub new {
    my $class = shift;
    bless {
	   indexes => {},
	   locales => {},
	   stemmer => Search::Xapian::Stem->new('english'),
	  }, $class;
}

sub _build_index {
    my ($self, $locale) = @_;
    if (exists $self->{locales}{$locale}) {
	return;
    }
    $self->{locales}{$locale} = 1;
    $self->{indexes}{$locale} = Search::Xapian::WritableDatabase->new();
}

sub _tokenize {
    my ($self, $str) = @_;
    my @terms = (map { $self->{stemmer}->stem_word($_) }
		 map { lc } split /\s+/, $str);
    return @terms;
}

sub index_msg {
    my ($self, $locale, $msg_id, $msg_str) = @_;
    if (!exists $self->{locales}{$locale}) {
	$self->_build_index($locale);
    }
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 0;
    my $pos = 0;
    my $doc = Search::Xapian::Document->new();
    for my $term ($self->_tokenize($msg_id)) {
	$doc->add_posting($term, $pos, 1);
    }
    $doc->set_data(Dumper [ $msg_id, $msg_str ]);
    $self->{indexes}{$locale}->add_document($doc);
}

sub translate_msg {
    my ($self, $locale, $msg_id) = @_;
    return if !$self->{indexes}{$locale};
    return if !$msg_id;
    my @tokens = $self->_tokenize($msg_id);
    return if !@tokens;
    my @translated_msgs;
    for my $op (OP_PHRASE, OP_NEAR, OP_AND, OP_OR) {
	my $query = Search::Xapian::Query->new($op, @tokens);
	my $enq = $self->{indexes}{$locale}->enquire($query);
	my $matches = $enq->get_mset(0, 20);
	next if !$matches->size();

	my $match = $matches->begin();
	for (1 .. $matches->size()) {
	    my $doc = $match->get_document();
	    my $msg_ref = eval $doc->get_data();
	    if ($@) {
		warn $@ if $@;
	    }
	    else {
		push @translated_msgs, $msg_ref;
	    }
	    $match++;
	}
	last if scalar @translated_msgs;
    }
    return wantarray ? @translated_msgs : $translated_msgs[0];
}

1;
__END__

=pod

=head1 NAME

Locale::Memories - L10N Message Retrieval

=head1 SYNOPSIS

  my $lm = Locale::Memories->new();
  $lm->index_msg($locale, $msg_id, $msg_str);
  $lm->translate_msg($locale, $msg_id);

=head1 DESCRIPTION

This module is specialized module for indexing and retrieving .po messages.

=head1 COPYRIGHT

Copyright (c) 2007 Yung-chung Lin. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
