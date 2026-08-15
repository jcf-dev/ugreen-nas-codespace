# Third-party notices

The container downloads, installs, or builds upon independent third-party
software, including code-server, Debian, Node.js, NVM, Python, uv, Git, GitHub
CLI, Docker CLI, Claude Code, OpenAI Codex CLI, OpenCode, npm packages, and Open
VSX extensions.

Those components are separate works distributed under their own licenses and
terms. Their inclusion does not change those licenses and does not imply that
their authors endorse this project. Image distributors are responsible for
retaining notices required by the versions they publish and for reviewing all
applicable upstream terms.

Primary upstream sources:

- code-server: <https://github.com/coder/code-server>
- NVM: <https://github.com/nvm-sh/nvm>
- Node.js: <https://github.com/nodejs/node>
- Python: <https://www.python.org/>
- uv: <https://github.com/astral-sh/uv>
- GitHub CLI: <https://github.com/cli/cli>
- Docker CLI: <https://github.com/docker/cli>
- Claude Code: <https://docs.anthropic.com/en/docs/claude-code/overview>
- OpenAI Codex CLI: <https://github.com/openai/codex>
- OpenCode: <https://github.com/anomalyco/opencode>
- Open VSX: <https://open-vsx.org/>

Run the following inside a built container to inspect Debian package copyright
files:

```bash
find /usr/share/doc -maxdepth 2 -name copyright -print
```

Project-authored material is covered by [LICENSE](LICENSE).
