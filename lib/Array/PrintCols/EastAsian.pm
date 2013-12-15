package Array::PrintCols::EastAsian;
use 5.010;
use strict;
use warnings;
use utf8;

use Carp;
use Encode;
use Data::Validator;
use Term::ReadKey;
use Text::VisualWidth::PP;
$Text::VisualWidth::PP::EastAsian = 1;

our $VERSION = "0.01";

sub max {
    my $max = shift;
    foreach (@_) { $max = $_ if $max < $_; }
    $max;
}

sub min {
    my $min = shift;
    foreach (@_) { $min = $_ if $min > $_; }
    $min;
}

sub validate {
    state $rules = Data::Validator->new(
        array  => { isa => 'ArrayRef' },
        gap    => { isa => 'Int', default => 0 },
        column => { isa => 'Int', optional => 1 },
        width  => { isa => 'Num', optional => 1 },
        align  => { isa => 'Str', default => 'left' },
        encode => { isa => 'Str', default => 'utf-8' },
    )->with('Sequenced');
    my $args = $rules->validate(@_);
    croak "Gap option should be a integer greater than or equal 1." if $args->{gap} < 0;
    croak "Column option should be a integer greater than 0."       if exists $args->{column} && $args->{column} <= 0;
    croak "Width option should be a number greater than 0."         if exists $args->{width} && $args->{width} <= 0;
    croak "Align option should be left, center, or right." unless $args->{align} =~ /^(left|center|right)$/i;
    return $args;
}

sub align {
    my $args    = shift;
    my @length  = map { Text::VisualWidth::PP::width $_ } @{ $args->{array} };
    my $max_len = max(@length);
    my ( @formatted_array, $space );
    for ( 0 .. $#{ $args->{array} } ) {
        $space = $max_len - $length[$_];
        push @formatted_array, $args->{array}->[$_]. " " x $space if $args->{align} =~ /^left$/i;
        push @formatted_array, " " x $space. $args->{array}->[$_] if $args->{align} =~ /^right$/i;
        if ( $args->{align} =~ /^center$/i ) {
            my $half_space = int $space / 2;
            push @formatted_array, " " x $half_space. $args->{array}->[$_]. " " x ($space - $half_space);
        }
    }
    return \@formatted_array;
}

sub format_cols {
    my $args = validate(@_);
    return align($args);
}

sub print_cols {
    my $args            = validate(@_);
    my $formatted_array = align($args);
    my $gap             = $args->{gap};
    my $encode          = $args->{encode};
    my $column          = $args->{column} if exists $args->{column};
    if ( exists $args->{width} ) {
        my $element_width = Text::VisualWidth::PP::width $formatted_array->[0];
        $column = max( 1, int 1 + ( $args->{width} - $element_width ) / ( $element_width + $gap ) );
        $column = min( $args->{column}, $column ) if exists $args->{column};
    }
    $column = $#{$formatted_array} unless $column;

    my $str = "";
    for ( 0 .. $#{$formatted_array} ) {
        unless ( $_ % $column ) {
            $str = $str . "\n" if $str;
        }
        else {
            $str = $str . " " x $gap;
        }
        $str = $str . $formatted_array->[$_];
    }
    print Encode::encode $encode, "$str\n";
}

sub pretty_print_cols {
    my ( $array, $options ) = @_;
    my $gap = $options->{gap} // 1;
    my @terminal_size = GetTerminalSize;
    my $align = $options->{align} // 'left';
    my $encode = $options->{encode} // 'utf-8';
    print_cols( $array, { 'gap' => $gap, 'width' => $terminal_size[0], 'align' => $align, 'encode' => $encode } );
}

1;
__END__

=encoding utf-8

=head1 NAME

Array::PrintCols::EastAsian - It's new $module

=head1 SYNOPSIS

    use Array::PrintCols::EastAsian;

=head1 DESCRIPTION

Array::PrintCols::EastAsian is ...

=head1 LICENSE

Copyright (C) zoncoen.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

zoncoen E<lt>zoncoen@gmail.comE<gt>

=cut

