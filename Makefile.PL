use inc::Module::Install;

name            ('Locale-Memories');
abstract        ("L10N Message Retrieval");
author          ('Yung-chung Lin <henearkrxern@gmail.org>');
version_from    ('lib/Locale/Memories.pm');
license         ('perl');

requires('File::Find::Rule');
requires('Locale::PO');
requires('Search::Xapian');

build_requires('Test::More');
install_script('bin/pomagic');
auto_install();

&WriteAll;

