#!/usr/bin/perl
#
# Script: convert-file-to-XML.pl
# Author: Jay Pike <jaypike@jinxed.net>
# Purpose: To convert a tab delimited text file
#   into a Excel formated file

package Main;

# Use statements
use strict;                     # Strict variable scopes
#use warnings;                   # Print general advisories
use Carp;                       # Error printing library
use Spreadsheet::WriteExcel;    # Load the Excel library
use Getopt::Long;               # Use the standard Perl module
#use Data::Dumper;               # To print hashes

# Global variables
my $pid = $$;
my $program_name = $0;
my $output_file = 'output.xls'; # These are overridden with cli options
my $input_file;            # These are overridden with cli options
my $default_worksheet = 'worksheet1';   # Default name of the worksheet
my $default_field_separator = '\t';     # Default field separator
my $max_field_width = 75;              # Max width of a column
my $additional_column_space = 1;        # Add space to columns
my %output_hash = ();
my ( $input_handle, $output_handle);

# Main program loop
my $self = Main->new();
$self->parse_command_line_options;
$self->check_file_names;
$self->read_file(\%output_hash);
$self->write_file(\%output_hash);

# --------------------------------------------------------------
# Sub routines below here
# --------------------------------------------------------------
sub check_file_names {
    if (( $input_file ne 'input.txt' )      # Change the output file name to
        && ( $output_file eq 'output.xls' ) # match the input file name, but
        && ( $input_file =~ m/\.txt$/ )) {  # with .xls rather than .txt if no output file specified.
        $output_file = $input_file;
        $output_file =~ s/^(.+)\.(txt|log)/$1.xls/;   # Change the .txt or .log to a .xls
        $output_file =~ s/^.*\/([^\/]+)$/$1/;         # Remove the directory 
    }
}

sub write_file {
    my $self = shift;
    my $output_hash_ref = shift;
    my $row = 0;
    my $col = 0;
    my %max_width = ();

    # Create a new Excel file
    my $excel = Spreadsheet::WriteExcel->new("$output_file");

    # Add a worksheet
    my $worksheet = $excel->add_worksheet("$default_worksheet");

    # Process the header information
    foreach my $field ( @{$output_hash_ref->{'header'}} ) {
        my $format = $excel->add_format();
        $format->set_bold();        # Set BOLD text
        $format->set_align('left'); # Set alignment
        $worksheet->write($row, $col, $field, $format);

        if ( ! defined $max_width{$col} ) {
            $max_width{$col} = length $field;
        }
        elsif ( (length $field) + $additional_column_space > $max_width{$col} ) {
            $max_width{$col} = (length $field) + $additional_column_space;
        }

        $col++;
    }

    # Process the data
    foreach my $line_number ( sort keys %{$output_hash_ref->{'data'}} ) {
        # Reset the columns and set the row to the line number
        $row = $line_number;
        $col = 0;
        foreach my $field ( @{$output_hash_ref->{'data'}->{$line_number}} ) {
            if ( ! defined $max_width{$col} ) {
                $max_width{$col} = length $field;
            }
            elsif ( (length $field) + $additional_column_space > $max_width{$col} ) {
                $max_width{$col} = (length $field) + $additional_column_space;
            }

            $worksheet->write($row, $col, $field);
            $col++;
        }
    }

    # Set the column widths
    foreach my $column_number ( sort keys %max_width ) {
        if ( $max_width{$column_number} > $max_field_width ) {
            $worksheet->set_column($column_number, $column_number, $max_field_width );
        }
        else {
            $worksheet->set_column($column_number, $column_number, $max_width{$column_number});
        }
    }

    $excel->close();
}

sub read_file {
    my ($self, $output_hash_ref) = @_;

    # Read in the file
    if ( -f $input_file && -r _ ) { # See if it is readable
        open $input_handle, "< $input_file" or croak "Error opening file: $input_file $!\n";

        my $input_line = 0;

        while ( my $inline = <$input_handle> ) {
            chomp $inline;

            if ( $input_line == 0 ) {
                # We have the header
                my @array =  split( $default_field_separator, $inline );
                $output_hash_ref->{'header'} = \@array;
                $input_line++;
            }
            else {
                # We have a line
                my @array =  split( $default_field_separator, $inline );
                $output_hash_ref->{'data'}->{$input_line} = \@array;
                $input_line++; 
            }
        }

        close $input_handle;

        $output_hash_ref->{'count'} = $input_line;
    }
    else {
        print "Error: $input_file $!\n";
        exit 1;
    }
}

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub parse_command_line_options () {
    my $options_okay = GetOptions (
        # Application-specific options
        'in=s'   => \$input_file,  # --in option expects a string
        'out=s'  => \$output_file,  # --out option expects a string
        'fs=s'  => \$default_field_separator,  # --fs option expects a string

        # Standard options
        'help'  => sub { print_usage(); },
        'h'     => sub { print_usage(); },
    );

    # Throw usage if options are not specified correctly
    print_usage() if (!$options_okay || $input_file eq '');
}

# Print usage information
sub print_usage {
    print "usage: $program_name -in <input text file>\n";
    print " options:\n";
    print "    -out <output text file>\n";
    print "    -fs <field separator>\n";
    exit 0;
}
