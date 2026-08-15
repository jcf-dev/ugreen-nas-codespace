'use strict';

const fs = require('fs');
const os = require('os');
const path = require('path');
const vscode = require('vscode');

const workspaceDirectory = '/workspace';
const stateDirectory = path.join(os.homedir(), '.config', 'ugreen-codespace');
const completionMarker = path.join(stateDirectory, 'onboarding-complete');

function isComplete() {
  return fs.existsSync(completionMarker);
}

function markComplete(mode) {
  fs.mkdirSync(stateDirectory, { recursive: true, mode: 0o700 });
  fs.writeFileSync(completionMarker, `${mode}\n`, { mode: 0o600 });
}

function workspaceHasFiles() {
  try {
    return fs.readdirSync(workspaceDirectory).length > 0;
  } catch (error) {
    return false;
  }
}

async function useBlankWorkspace() {
  try {
    fs.mkdirSync(workspaceDirectory, { recursive: true });
    fs.accessSync(workspaceDirectory, fs.constants.R_OK | fs.constants.W_OK);
  } catch (error) {
    await vscode.window.showErrorMessage(
      'The /workspace mount is not writable. Fix its UGOS ownership or the Compose UID/GID, then run First-Run Setup again.'
    );
    return;
  }

  if (workspaceHasFiles()) {
    const answer = await vscode.window.showWarningMessage(
      'The workspace already contains files. Blank project will keep every existing file and use this folder as-is.',
      { modal: true },
      'Use existing workspace'
    );
    if (answer !== 'Use existing workspace') {
      return;
    }
  }

  markComplete('blank');
  await vscode.window.showInformationMessage(
    'Your workspace is ready. Create files in /workspace; they persist on the NAS.'
  );
}

async function cloneFromGitHub() {
  const repository = await vscode.window.showInputBox({
    title: 'UGREEN NAS Codespace · GitHub',
    prompt: 'Enter OWNER/REPOSITORY or a github.com repository URL',
    placeHolder: 'octocat/Hello-World',
    ignoreFocusOut: true,
    validateInput(value) {
      if (!value.trim()) {
        return 'Enter a GitHub repository.';
      }
      if (/\s/.test(value)) {
        return 'Repository names and URLs cannot contain spaces.';
      }
      return undefined;
    }
  });

  if (!repository) {
    return;
  }

  const terminal = vscode.window.createTerminal({
    name: 'GitHub project setup',
    shellPath: '/usr/local/bin/ugreen-onboard',
    shellArgs: ['github', repository.trim()]
  });
  terminal.show();
  await vscode.window.showInformationMessage(
    'Continue project setup in the terminal. GitHub will request browser sign-in when needed.'
  );
}

async function runOnboarding(force = false) {
  if (!force && isComplete()) {
    return;
  }

  const selection = await vscode.window.showQuickPick(
    [
      {
        label: 'Project source',
        kind: vscode.QuickPickItemKind.Separator
      },
      {
        label: '$(new-folder) Blank project',
        description: 'Create or use /workspace',
        detail: 'Keeps every existing NAS file and asks before using a non-empty folder.',
        mode: 'blank'
      },
      {
        label: '$(github) Clone from GitHub',
        description: 'Public or private repository',
        detail: 'Uses GitHub CLI browser sign-in and supports organization SAML SSO.',
        mode: 'github'
      },
      {
        label: 'Future providers',
        kind: vscode.QuickPickItemKind.Separator
      },
      {
        label: '$(git-branch) GitLab',
        description: 'Coming soon',
        detail: 'GitLab authentication and cloning are not enabled yet.',
        mode: 'gitlab'
      },
      {
        label: 'Other',
        kind: vscode.QuickPickItemKind.Separator
      },
      {
        label: '$(clock) Ask me later',
        description: 'Decide next time',
        detail: 'Shows this native setup picker again in the next browser session.',
        mode: 'later'
      }
    ],
    {
      title: 'UGREEN NAS Codespace',
      placeHolder: 'How would you like to start?',
      ignoreFocusOut: true,
      matchOnDescription: true,
      matchOnDetail: true
    }
  );

  if (!selection || selection.mode === 'later') {
    return;
  }
  if (selection.mode === 'blank') {
    await useBlankWorkspace();
  } else if (selection.mode === 'github') {
    await cloneFromGitHub();
  } else {
    await vscode.window.showInformationMessage(
      'GitLab onboarding is planned for a future release. Choose Blank project or GitHub for now.'
    );
  }
}

function activate(context) {
  context.subscriptions.push(
    vscode.commands.registerCommand('ugreenCodespace.runOnboarding', () => runOnboarding(true)),
    vscode.commands.registerCommand('ugreenCodespace.resetOnboarding', async () => {
      try {
        fs.rmSync(completionMarker, { force: true });
        await vscode.window.showInformationMessage('First-run project setup was reset.');
        await runOnboarding(true);
      } catch (error) {
        await vscode.window.showErrorMessage(`Could not reset first-run setup: ${error.message}`);
      }
    })
  );

  void runOnboarding(false);
}

function deactivate() {}

module.exports = { activate, deactivate };
