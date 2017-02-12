# Jekyll Browsersync

Add live reloading to your Jekyll development using [Browsersync](https://www.browsersync.io/).

## Requirements

* Jekyll >= 3
* [Browsersync](https://www.browsersync.io/) installed
  * globally (`npm install -g browser-sync` ) **OR**
  * locally (`npm install browser-sync`)

## Installation

Add this line to your application's Gemfile:

    gem 'jekyll-browsersync', group: [:jekyll_plugins]

Then install it

    $ bundle

## Usage

Once you have it installed, you should have a new `browser-sync` command under Jekyll.

    $ bundle exec jekyll browser-sync

If you have Browsersync installed in a custom location, you can specify this with the
`--browser-sync` option.

    $ bundle exec jekyll browsersync --browser-sync ~/bin/browser-sync

If you would like to serve the site using https, use the `--https` option.

    $ bundle exec jekyll bs --https

### `bs-config.js`

If you want to customize the browser-sync options further, you can instruct the command
to generate a `bs-config.js` file (and later customize it):

    $ bundle exec jekyll browsersync --bs-config my-bs-config.js

If `my-bs-config.js` exists, it will be used by the command. If it doesn't exist, it will
be generated with the given/default options.
If you use a baseurl in your Jekyll site, a route for that is created in the bs-config file.

If you don't specify a file name, like

    $ bundle exec jekyll browsersync --bs-config

the command will generate a temporary bs-config file (named `.bs-config.RANDOMCHARS.js`) and
automatically delete it on exit.

## Contributing

1. Fork it (https://github.com/mloberg/jekyll-browsersync/fork)
2. Create your feature branch (`git checkout -b feature/my-awesome-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin feature/my-awesome-feature`)
5. Create new Pull Request

## TODO

* Write tests
