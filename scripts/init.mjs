#!/usr/bin/env node
// One-time project initialiser. Run from the repository root of a COPY of the template:
//   node scripts/init.mjs
// Options (all optional; missing values are asked interactively):
//   --app-name "Friends App"  --slug friends-app  --bundle-id com.example.friendsapp
//   --repo my-repo  --visibility private|public  --approver <github-login>
//   --yes          accept defaults without asking
//   --patch-only   only replace the placeholders in files (no git, no GitHub)
//   --dry-run      print the git/gh commands instead of running them
import { spawnSync } from 'node:child_process';
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { basename, resolve } from 'node:path';
import { createInterface } from 'node:readline/promises';

const argv = process.argv.slice(2);
const opt = {};
for (let i = 0; i < argv.length; i++) {
  if (!argv[i].startsWith('--')) continue;
  const key = argv[i].slice(2);
  const next = argv[i + 1];
  if (next === undefined || next.startsWith('--')) opt[key] = true;
  else { opt[key] = next; i++; }
}
const dry = opt['dry-run'] === true;
const patchOnly = opt['patch-only'] === true;
const yes = opt['yes'] === true;

const rl = createInterface({ input: process.stdin, output: process.stdout });
const say = (m = '') => console.log(m);
async function ask(question, def) {
  if (yes) return def;
  const a = (await rl.question(`${question}${def ? ` [${def}]` : ''}: `)).trim();
  return a || def;
}

function run(cmd, args, { inherit = false, allowFail = false } = {}) {
  if (dry) { say(`  $ ${cmd} ${args.join(' ')}`); return { status: 0, stdout: '', stderr: '' }; }
  const r = spawnSync(cmd, args, { encoding: 'utf8', stdio: inherit ? 'inherit' : 'pipe' });
  if (r.error) {
    if (allowFail) return { status: 1, stdout: '', stderr: String(r.error) };
    throw new Error(`Could not run "${cmd}". Is it installed and on your PATH? (${r.error.message})`);
  }
  if (r.status !== 0 && !allowFail) {
    throw new Error(`Command failed: ${cmd} ${args.join(' ')}\n${r.stderr || ''}`);
  }
  return r;
}

const slugify = (s) => s.toLowerCase().normalize('NFKD').replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '') || 'app';
const bundleSafe = (s) => s.toLowerCase().replace(/[^a-z0-9]/g, '') || 'app';

function patchFiles(map, files) {
  for (const f of files) {
    if (!existsSync(f)) { say(`  (skip, not found: ${f})`); continue; }
    let text = readFileSync(f, 'utf8');
    let changed = false;
    for (const [from, to] of Object.entries(map)) {
      if (text.includes(from)) { text = text.split(from).join(to); changed = true; }
    }
    if (changed) { writeFileSync(f, text); say(`  patched ${f}`); }
  }
}

async function main() {
  say('Agentic mobile template - project initialiser\n');
  const root = resolve('.');
  if (!existsSync('app/app.json') || !existsSync('.github/labels.json')) {
    throw new Error('Run this from the repository root (the folder that contains app/ and .github/).');
  }

  let login = '';
  if (!patchOnly) {
    run('git', ['--version']);
    run('gh', ['--version']);
    const auth = run('gh', ['auth', 'status'], { allowFail: true });
    if (auth.status !== 0 && !dry) throw new Error('GitHub CLI is not logged in. Run:  gh auth login   and start this script again.');
    login = dry ? 'your-login' : run('gh', ['api', 'user', '--jq', '.login']).stdout.trim();
  }

  const folder = basename(root);
  const appName = opt['app-name'] || await ask('App display name', folder.replace(/^_+/, '') || 'My App');
  const slug = slugify(opt['slug'] || await ask('App slug (lowercase, dashes)', slugify(appName)));
  const owner = opt['approver'] || await ask('GitHub login of the approver (the only person who can approve gates)', login || 'your-login');
  const bundleId = opt['bundle-id'] || await ask('Bundle id / Android package (reverse-DNS, lowercase)', `com.${bundleSafe(owner)}.${bundleSafe(slug)}`);
  const repoName = opt['repo'] || await ask('GitHub repository name', slug);
  const visibility = (opt['visibility'] || await ask('Repository visibility (private/public)', 'private')).toLowerCase();
  if (!['private', 'public'].includes(visibility)) throw new Error('visibility must be private or public');
  if (!/^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)+$/.test(bundleId)) throw new Error(`Invalid bundle id "${bundleId}" (example: com.example.friendsapp)`);

  say('\n1/7 Replacing placeholders');
  patchFiles(
    { __APP_NAME__: appName, __APP_SLUG__: slug, __BUNDLE_ID__: bundleId, __OWNER__: owner },
    ['app/app.json', 'docs/SPEC.md', '.github/CODEOWNERS', 'README.md'],
  );
  if (patchOnly) { say('\nDone (patch only).'); return; }

  say('\n2/7 Git repository');
  if (!existsSync('.git')) {
    run('git', ['init', '-b', 'main']);
    run('git', ['add', '-A']);
    const c = run('git', ['commit', '-m', 'chore: initialise from agentic template'], { allowFail: true });
    if (c.status !== 0) throw new Error(`git commit failed (is user.name / user.email configured?)\n${c.stderr}`);
  } else say('  .git already exists - keeping history');

  say('\n3/7 GitHub repository');
  const hasOrigin = run('git', ['remote', 'get-url', 'origin'], { allowFail: true }).status === 0;
  if (!hasOrigin) run('gh', ['repo', 'create', repoName, `--${visibility}`, '--source', '.', '--remote', 'origin', '--push'], { inherit: true });
  else say('  remote origin exists - not creating a repository');
  const repo = dry ? `${owner}/${repoName}` : run('gh', ['repo', 'view', '--json', 'nameWithOwner', '--jq', '.nameWithOwner']).stdout.trim();
  say(`  repository: ${repo}`);

  say('\n4/7 Actions settings (workflows may create pull requests)');
  run('gh', ['api', '-X', 'PUT', `repos/${repo}/actions/permissions/workflow`, '-f', 'default_workflow_permissions=write', '-F', 'can_approve_pull_request_reviews=true']);

  say('\n5/7 Labels and approver variable');
  const labels = JSON.parse(readFileSync('.github/labels.json', 'utf8'));
  for (const l of labels) {
    run('gh', ['label', 'create', l.name, '--color', l.color, '--description', l.description, '--force', '--repo', repo], { allowFail: true });
  }
  run('gh', ['variable', 'set', 'APPROVER', '--body', owner, '--repo', repo]);

  say('\n6/7 Agent credentials');
  say('  Create a token with the Claude CLI:  claude setup-token   (it prints a long-lived token for CI).');
  const setSecret = yes ? 'n' : (await ask('Set the secret CLAUDE_CODE_OAUTH_TOKEN now? (y/n)', 'y')).toLowerCase();
  if (setSecret.startsWith('y')) run('gh', ['secret', 'set', 'CLAUDE_CODE_OAUTH_TOKEN', '--repo', repo], { inherit: true });
  else say(`  Later:  gh secret set CLAUDE_CODE_OAUTH_TOKEN --repo ${repo}`);

  say('\n7/7 Branch protection (ruleset for main)');
  const rs = run('gh', ['api', '-X', 'POST', `repos/${repo}/rulesets`, '--input', '.github/ruleset-main.json'], { allowFail: true });
  if (rs.status === 0) say('  ruleset created: main requires a pull request and the agentic/* status checks');
  else {
    say('  Could not create the ruleset:');
    say('  ' + String(rs.stderr || '').split('\n').slice(0, 3).join('\n  '));
    say('  On GitHub Free, rulesets/branch protection exist only for PUBLIC repositories; private repositories need GitHub Pro.');
    say('  The pipeline still works, but merging is then protected by discipline + the main-watch alert, not by GitHub.');
    say('  See SETUP.md, section "What is enforced and what is not".');
  }

  say('\nDone. Next steps:');
  say(`  1. Install the Claude GitHub App on the repository: https://github.com/apps/claude`);
  say('  2. Fill in docs/SPEC.md, commit and push to main.');
  say('  3. Create your Supabase project and app/.env (see SETUP.md, step 6).');
  say('  4. Smoke test: create an issue from the "Idea" form using docs/examples/first-idea.md.');
}

main().catch((e) => { console.error(`\nERROR: ${e.message}`); process.exitCode = 1; }).finally(() => rl.close());
