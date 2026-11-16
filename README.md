# claudiuhromei.github.io

Personal website of Claudiu Daniel Hromei — Senior AI Scientist and AI researcher (NLP, LLMs, multimodal grounding, agentic AI).

Built with [Jekyll](https://jekyllrb.com/) and the [Minimal Mistakes](https://mmistakes.github.io/minimal-mistakes/) theme, deployed to GitHub Pages with GitHub Actions.

## Development

```sh
bundle config set --local path vendor/bundle
bundle install
bundle exec rake serve   # preview at http://localhost:4000
bundle exec rake test    # build + unit tests + html-proofer
```

## Tests

`bundle exec rake test` builds the site and runs four suites: the minitest checks on the generated HTML (`test/`), html-proofer, the pytest suite of the helper scripts (`tools/`) and the browser tests (`browser_tests/`, Playwright). The last two need [uv](https://docs.astral.sh/uv/); the browser tests use the installed Edge on Windows and the Chromium installed by Playwright elsewhere.
