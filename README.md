# Series Backlink

This Koha display plugin keeps Koha's standard MARC21 series link with `830$w`
unchanged. When the NM2DB API resolves the control number uniquely, it adds a
second link labelled "Go to parent record" to the linked record's detail page.

It runs on bibliographic detail pages in both the OPAC and the staff interface.
It uses Koha's existing `rcn:` series links as input, so it does not alter MARC
records, XSLT files, or Koha core templates.

## Dependency

Install and enable `koha-plugin-nm2db-api` first. It provides:

```text
/api/v1/contrib/hks3-nm2db/control-numbers/{control_number}
```

When the API is unavailable, finds no record, or finds several records, no
extra link is added. The original Koha `rcn:` search link always remains in
place. The plugin never selects an ambiguous target.

## Translations

The plugin uses `Koha::I18N` for its user-visible metadata and link label.
English and German PO fragments are in `po/`. Merge the selected fragment into
Koha's active messages catalog with `msgcat`, validate it with `msgfmt --check`,
and compile the resulting `Koha.mo` in Koha's locale directory. The target
system must have the selected locale installed, for example `de_DE.utf8`.

## Build

```sh
scripts/build-kpz
```

The package is written to `dist/koha-plugin-series-backlink-vVERSION.kpz`.

## License

This plugin is licensed under the GNU General Public License, version 3 or
later. See `LICENSE`.
