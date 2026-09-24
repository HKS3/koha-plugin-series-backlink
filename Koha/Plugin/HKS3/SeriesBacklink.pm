package Koha::Plugin::HKS3::SeriesBacklink;

use Modern::Perl;

use base qw(Koha::Plugins::Base);

use JSON qw(encode_json);
use Koha::I18N qw(__);

our $VERSION = '0.1.1';

our $metadata = {
    name            => 'Series Backlink',
    author          => 'HKS3',
    description     => 'Open uniquely linked series records directly',
    namespace       => 'hks3-series-backlink',
    date_authored   => '2026-09-24',
    date_updated    => '2026-09-24',
    minimum_version => '26.05',
    maximum_version => undef,
    version         => $VERSION,
};

sub new {
    my ( $class, $args ) = @_;

    my %localized_metadata = %{$metadata};
    $localized_metadata{name}        = __('Series Backlink');
    $localized_metadata{description} = __('Open uniquely linked series records directly');

    $args->{metadata}        = \%localized_metadata;
    $args->{metadata}{class} = $class;

    return $class->SUPER::new($args);
}

sub intranet_js {
    my ( $self, $params ) = @_;

    return q{} unless ( $params->{page} // q{} ) eq '/cgi-bin/koha/catalogue/detail.pl';
    return _backlink_javascript('intranet');
}

sub opac_js {
    return _backlink_javascript('opac');
}

sub install { return 1; }
sub upgrade { return 1; }
sub uninstall { return 1; }

sub _backlink_javascript {
    my ($interface) = @_;

    my $config = encode_json(
        {
            interface => $interface,
            endpoint  => '/api/v1/contrib/hks3-nm2db/control-numbers/',
            label     => __('Go to parent record'),
            detail    => $interface eq 'opac'
                ? '/cgi-bin/koha/opac-detail.pl?biblionumber='
                : '/cgi-bin/koha/catalogue/detail.pl?biblionumber=',
        }
    );

    return <<"JS";
<script>
(function () {
    "use strict";

    const config = $config;
    const expectedPath = config.interface === "opac"
        ? "/cgi-bin/koha/opac-detail.pl"
        : "/cgi-bin/koha/catalogue/detail.pl";
    if (window.location.pathname !== expectedPath) {
        return;
    }

    function controlNumberFromLink(link) {
        const url = new URL(link.href, window.location.origin);
        const query = url.searchParams.get("q") || "";
        const match = query.match(/(?:^|\\s)rcn:([^\\s]+)/);
        return match ? match[1] : null;
    }

    document.querySelectorAll(".results_summary.series a[href]").forEach(function (link) {
        const controlNumber = controlNumberFromLink(link);
        if (!controlNumber || link.dataset.hks3ControlNumberResolver) {
            return;
        }

        link.dataset.hks3ControlNumberResolver = "pending";
        fetch(config.endpoint + encodeURIComponent(controlNumber), {
            credentials: "same-origin",
            headers: { "Accept": "application/json" }
        })
            .then(function (response) {
                return response.ok ? response.json() : null;
            })
            .then(function (resolved) {
                if (!resolved || !Number.isInteger(resolved.biblionumber) || resolved.biblionumber < 1) {
                    return;
                }
                const parentLink = document.createElement("a");
                parentLink.href = config.detail + encodeURIComponent(String(resolved.biblionumber));
                parentLink.className = "hks3-series-backlink";
                parentLink.textContent = config.label;
                link.after(document.createTextNode(" | "), parentLink);
                link.dataset.hks3ControlNumberResolver = "resolved";
            })
            .catch(function () {
                // Keep Koha's control-number search as the fallback link.
            });
    });
})();
</script>
JS
}

1;
