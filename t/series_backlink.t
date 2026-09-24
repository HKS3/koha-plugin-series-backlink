use Modern::Perl;

use Cwd qw(abs_path);
use File::Temp qw(tempfile);
use FindBin qw($Bin);
use Test::More;

BEGIN {
    package Koha::Plugins::Base;

    sub new {
        my ( $class, $args ) = @_;
        return bless $args, $class;
    }

    $INC{'Koha/Plugins/Base.pm'} = 1;

    package Koha::I18N;

    sub __ { return $_[0]; }

    sub import {
        my $caller = caller;
        no strict 'refs';
        *{"${caller}::__"} = \&__;
    }

    $INC{'Koha/I18N.pm'} = 1;
}

use lib abs_path("$Bin/..");
use Koha::Plugin::HKS3::SeriesBacklink;

my $plugin = Koha::Plugin::HKS3::SeriesBacklink->new( { enable_plugins => 1 } );
ok( $plugin, 'creates the series backlink plugin' );

is(
    $plugin->intranet_js( { page => '/cgi-bin/koha/mainpage.pl' } ),
    q{},
    'does not inject JavaScript outside staff catalogue details'
);

my $intranet_js = $plugin->intranet_js( { page => '/cgi-bin/koha/catalogue/detail.pl' } );
like( $intranet_js, qr{/api/v1/contrib/hks3-nm2db/control-numbers/}, 'uses the independent NM2DB API endpoint' );
like( $intranet_js, qr{/cgi-bin/koha/catalogue/detail\.pl\?biblionumber=}, 'resolves to staff details' );
like( $intranet_js, qr/\.results_summary\.series a\[href\]/, 'only enhances displayed series links' );
like( $intranet_js, qr/rcn:/, 'uses Koha control-number series links as input' );
like( $intranet_js, qr/Keep Koha's control-number search as the fallback link/, 'keeps the standard fallback' );
like( $intranet_js, qr/Go to parent record/, 'adds a translated parent-record link label' );
like( $intranet_js, qr/parentLink\.href = config\.detail/, 'creates a separate parent-record link' );
unlike( $intranet_js, qr/link\.href = config\.detail/, 'does not replace Koha standard series links' );

my $opac_js = $plugin->opac_js;
like( $opac_js, qr{/cgi-bin/koha/opac-detail\.pl\?biblionumber=}, 'resolves to OPAC details' );
like( $opac_js, qr/opac-detail\.pl/, 'limits the OPAC JavaScript to OPAC detail pages' );

my ($javascript_fh, $javascript_path) = tempfile( SUFFIX => '.js', UNLINK => 1 );
my $javascript = $intranet_js;
$javascript =~ s{\A<script>\n}{};
$javascript =~ s{</script>\n?\z}{};
print {$javascript_fh} $javascript;
close $javascript_fh;
is( system( 'node', '--check', $javascript_path ) >> 8, 0, 'generated intranet JavaScript parses' );

done_testing();
