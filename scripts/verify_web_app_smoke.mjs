import { mkdir, writeFile } from 'node:fs/promises';
import { dirname } from 'node:path';
import { chromium } from 'playwright';

const args = parseArgs(process.argv.slice(2));
const baseUrl = trimTrailingSlash(args.baseUrl ?? process.env.FLOWFIT_WEB_SMOKE_BASE_URL);
const outFile = args.outFile ?? '';
const timeoutMs = Number.parseInt(args.timeoutMs ?? '30000', 10);
const browserExecutable =
  args.browserExecutable ?? process.env.FLOWFIT_BROWSER_EXECUTABLE ?? '';

if (!baseUrl) {
  throw new Error('Provide --base-url or FLOWFIT_WEB_SMOKE_BASE_URL.');
}

const consoleMessages = [];
const failedRequests = [];
const steps = [];

function recordStep(name, detail = '') {
  steps.push({ level: 'PASS', name, detail });
  console.log(`[PASS] ${name}${detail ? ` - ${detail}` : ''}`);
}

function normalizeUrl(path) {
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  return `${baseUrl}${path.startsWith('/') ? path : `/${path}`}`;
}

function trimTrailingSlash(value) {
  if (!value) return '';
  return value.trim().replace(/\/+$/, '');
}

function parseArgs(values) {
  const parsed = {};
  for (let index = 0; index < values.length; index += 1) {
    const value = values[index];
    if (!value.startsWith('--')) continue;
    const key = value.slice(2).replace(/-([a-z])/g, (_, char) => char.toUpperCase());
    const next = values[index + 1];
    if (!next || next.startsWith('--')) {
      parsed[key] = 'true';
    } else {
      parsed[key] = next;
      index += 1;
    }
  }
  return parsed;
}

async function waitForText(page, text) {
  await page.waitForFunction(
    (expectedText) => document.body.innerText.includes(expectedText),
    text,
    { timeout: timeoutMs },
  );
}

async function waitForTextMatch(page, matcher) {
  await page.waitForFunction(
    (source) => new RegExp(source, 'i').test(document.body.innerText),
    matcher.source,
    { timeout: timeoutMs },
  );
}

async function waitForAnyText(page, texts, timeout = timeoutMs) {
  await page.waitForFunction(
    (expectedTexts) =>
      expectedTexts.some((expectedText) =>
        document.body.innerText.includes(expectedText),
      ),
    texts,
    { timeout },
  );
}

async function clickText(page, text) {
  const button = page
    .locator('flt-semantics[role="button"]')
    .filter({ hasText: text })
    .first();
  await button.waitFor({ state: 'visible', timeout: timeoutMs });
  await button.click({ timeout: timeoutMs });
}

async function clickExactText(page, text) {
  const target = page.getByText(text, { exact: true }).first();
  await target.waitFor({ state: 'visible', timeout: timeoutMs });
  try {
    await target.click({ timeout: timeoutMs });
  } catch {
    await target.click({ timeout: timeoutMs, force: true });
  }
}

async function clickTextAnywhere(page, text) {
  const button = page
    .locator('flt-semantics[role="button"]')
    .filter({ hasText: text })
    .first();
  if ((await button.count()) > 0) {
    await button.waitFor({ state: 'visible', timeout: timeoutMs });
    await button.click({ timeout: timeoutMs });
    return;
  }

  await clickExactText(page, text);
}

async function enableFlutterSemantics(page) {
  await page.waitForLoadState('networkidle', { timeout: timeoutMs });
  await page.evaluate(() => {
    const placeholder = document.querySelector('flt-semantics-placeholder');
    if (placeholder instanceof HTMLElement) {
      placeholder.click();
    }
  });
  await page.keyboard.press('Tab').catch(() => {});
  await page.waitForTimeout(500);
}

async function gotoRoute(page, route) {
  await page.goto(normalizeUrl(`/#${route}`), {
    waitUntil: 'networkidle',
    timeout: timeoutMs,
  });
  await enableFlutterSemantics(page);
}

async function expectRouteText(page, route, expectedText, name) {
  await gotoRoute(page, route);
  await waitForText(page, expectedText);
  recordStep(name, route);
}

let browser;
let page;

async function writeEvidence(summary) {
  if (!outFile) return;

  await mkdir(dirname(outFile), { recursive: true });
  await writeFile(outFile, `${JSON.stringify(summary, null, 2)}\n`, 'utf8');
  console.log(`Web app smoke evidence written: ${outFile}`);
}

try {
  browser = await chromium.launch({
    headless: true,
    ...(browserExecutable ? { executablePath: browserExecutable } : {}),
  });
  page = await browser.newPage({ viewport: { width: 1280, height: 720 } });

  page.on('console', (message) => {
    if (['error', 'warning'].includes(message.type())) {
      consoleMessages.push({
        type: message.type(),
        text: message.text(),
        pageUrl: page.url(),
        previousStep: steps.at(-1)?.name ?? '',
        location: message.location(),
      });
    }
  });

  page.on('requestfailed', (request) => {
    failedRequests.push({
      url: request.url(),
      method: request.method(),
      failure: request.failure()?.errorText ?? 'unknown',
    });
  });

  await page.goto(normalizeUrl('/#/welcome'), {
    waitUntil: 'networkidle',
    timeout: timeoutMs,
  });
  await enableFlutterSemantics(page);
  await waitForText(page, 'Find Your Flow');
  await waitForText(page, 'Get Started');
  await waitForText(page, 'Log In');
  recordStep('Welcome screen rendered', '#/welcome');

  await clickText(page, 'Get Started');
  await page.waitForURL(/#\/signup/, { timeout: timeoutMs });
  await enableFlutterSemantics(page);
  await waitForText(page, 'Create Account');
  await waitForText(page, 'Email');
  await waitForText(page, 'Password');
  await waitForText(page, 'Terms');
  await waitForText(page, 'Privacy');
  recordStep('Signup screen rendered after Get Started', '#/signup');

  await clickText(page, 'Log In');
  await page.waitForURL(/#\/login/, { timeout: timeoutMs });
  recordStep('Signup Log In link reached login route', '#/login');

  await page.goto(normalizeUrl('/#/login'), {
    waitUntil: 'networkidle',
    timeout: timeoutMs,
  });
  await enableFlutterSemantics(page);
  await waitForText(page, 'Email');
  await waitForText(page, 'Password');
  await waitForTextMatch(page, /Forgot password\?/i);
  await waitForText(page, 'Sign Up');
  recordStep('Login screen rendered from direct route', '#/login');

  await clickText(page, 'Sign Up');
  await page.waitForURL(/#\/signup/, { timeout: timeoutMs });
  recordStep('Login Sign Up link returned to signup', '#/signup');

  await page.goto(normalizeUrl('/#/survey_intro'), {
    waitUntil: 'networkidle',
    timeout: timeoutMs,
  });
  await enableFlutterSemantics(page);
  await waitForText(page, 'Quick Setup');
  await waitForTextMatch(page, /personalize FlowFit/i);
  await waitForText(page, "Let's Personalize");
  recordStep('Survey intro rendered from direct route', '#/survey_intro');

  await clickText(page, "Let's Personalize");
  await page.waitForURL(/#\/survey_basic_info/, { timeout: timeoutMs });
  await enableFlutterSemantics(page);
  await waitForText(page, 'Tell us about yourself');
  await waitForText(page, 'Gender');
  await waitForText(page, 'Continue');
  recordStep(
    'Survey intro primary action reached basic info',
    '#/survey_basic_info',
  );

  await clickExactText(page, 'Male');
  await clickText(page, 'Continue');
  await page.waitForURL(/#\/survey_body_measurements/, { timeout: timeoutMs });
  await enableFlutterSemantics(page);
  await waitForText(page, 'Your measurements');
  await waitForText(page, 'Height');
  await waitForText(page, 'Weight');
  recordStep(
    'Survey basic info gender and Continue reached measurements',
    '#/survey_body_measurements',
  );

  await page.goto(normalizeUrl('/#/buddy-welcome'), {
    waitUntil: 'networkidle',
    timeout: timeoutMs,
  });
  await enableFlutterSemantics(page);
  await waitForTextMatch(page, /Meet Your\s+Fitness Buddy/i);
  await waitForText(page, "LET'S GO!");
  recordStep('Buddy welcome rendered from direct route', '#/buddy-welcome');

  await clickText(page, "LET'S GO!");
  await page.waitForURL(/#\/buddy-intro/, { timeout: timeoutMs });
  await enableFlutterSemantics(page);
  await waitForText(page, 'Splash splash, thanks for finding me.');
  await waitForText(page, "what's your name?");
  await waitForText(page, 'Skip');
  recordStep('Buddy welcome primary action reached intro', '#/buddy-intro');

  await gotoRoute(page, '/age-gate');
  await waitForText(page, 'Welcome to FlowFit!');
  await clickTextAnywhere(page, "I'm 7-12 years old");
  await page.waitForURL(/#\/buddy-welcome/, { timeout: timeoutMs });
  await enableFlutterSemantics(page);
  await waitForTextMatch(page, /Meet Your\s+Fitness Buddy/i);
  recordStep('Age gate kids action reached Buddy welcome', '#/buddy-welcome');

  await gotoRoute(page, '/age-gate');
  await waitForText(page, 'Welcome to FlowFit!');
  await clickTextAnywhere(page, "I'm 13 or older");
  await page.waitForURL(/#\/survey_intro/, { timeout: timeoutMs });
  await enableFlutterSemantics(page);
  await waitForText(page, 'Quick Setup');
  recordStep('Age gate teen/adult action reached survey intro', '#/survey_intro');

  const safeRouteEntryChecks = [
    ['/survey_activity_goals', 'Activity & Goals', 'Survey activity goals route rendered'],
    ['/survey_daily_targets', 'Your Daily Targets', 'Survey daily targets route rendered'],
    ['/onboarding1', 'Track Your Heart Rate', 'Legacy onboarding route rendered'],
    ['/weight-goals', 'Weight Goals', 'Weight goals route rendered'],
    ['/fitness-goals', 'Fitness Goals', 'Fitness goals route rendered'],
    ['/nutrition-goals', 'Nutrition Goals', 'Nutrition goals route rendered'],
    ['/workout/running/summary', 'Back to Dashboard', 'Running summary empty route rendered'],
    [
      '/workout/running/share',
      'No running session is available to share.',
      'Running share guarded route rendered',
    ],
    ['/workout/walking/options', 'Choose Walking Mode', 'Walking options route rendered'],
    ['/workout/walking/mission', 'Create Mission', 'Walking mission creation route rendered'],
    ['/workout/walking/active', 'No active walking session', 'Walking active empty route rendered'],
    ['/workout/walking/summary', 'Back to Dashboard', 'Walking summary empty route rendered'],
    [
      '/workout/resistance/select-split',
      'Choose Your Split',
      'Resistance split selection route rendered',
    ],
    [
      '/workout/resistance/active',
      'No active resistance workout',
      'Resistance active empty route rendered',
    ],
    [
      '/workout/resistance/summary',
      'No completed workout available',
      'Resistance summary empty route rendered',
    ],
    ['/wellness-tracker', 'Welcome to Wellness Tracker', 'Wellness tracker route rendered'],
    ['/wellness-onboarding', 'Welcome to Wellness Tracker', 'Wellness onboarding route rendered'],
    ['/wellness-settings', 'Wellness Settings', 'Wellness settings route rendered'],
    ['/buddy-color-selection', 'Choose your Whale Color!', 'Buddy color route rendered'],
    [
      '/buddy-naming',
      'What do you want to name your baby whale?',
      'Buddy naming route rendered',
    ],
    ['/goal-selection', 'What areas would you like support with?', 'Goal selection route rendered'],
    ['/notification-permission', 'Maybe later', 'Notification permission route rendered'],
    ['/buddy-ready', 'START ADVENTURE!', 'Buddy ready route rendered'],
    ['/buddy_profile_setup', 'Tell Buddy about yourself!', 'Buddy profile setup route rendered'],
    [
      '/buddy-customization',
      'Please log in to customize your Buddy',
      'Buddy customization guarded route rendered',
    ],
  ];

  for (const [route, expectedText, name] of safeRouteEntryChecks) {
    await expectRouteText(page, route, expectedText, name);
  }

  await gotoRoute(page, '/home');
  await waitForText(page, 'FlowFit');
  await waitForText(page, 'Current Heart Rate');
  await waitForText(page, 'No data yet');
  await waitForText(page, 'Clear');
  recordStep('Phone home data surface rendered', '#/home');

  await clickText(page, 'Clear');
  await waitForText(page, 'Clear All Data');
  await waitForText(page, 'Cancel');
  await clickText(page, 'Cancel');
  await enableFlutterSemantics(page);
  recordStep('Phone home Clear action opens and cancels dialog', '#/home');

  await gotoRoute(page, '/workout/select-type');
  await waitForText(page, 'Choose Your Workout');
  await clickTextAnywhere(page, 'Running');
  await page.waitForURL(/#\/workout\/running\/setup/, { timeout: timeoutMs });
  await enableFlutterSemantics(page);
  await waitForText(page, 'Running Setup');
  recordStep('Workout Running action reached setup route', '#/workout/running/setup');

  await gotoRoute(page, '/workout/select-type');
  await clickTextAnywhere(page, 'Walking');
  await page.waitForURL(/#\/workout\/walking\/options/, { timeout: timeoutMs });
  await enableFlutterSemantics(page);
  await waitForText(page, 'Choose Walking Mode');
  recordStep('Workout Walking action reached options route', '#/workout/walking/options');

  await clickTextAnywhere(page, 'Sanctuary');
  await waitForText(page, 'Reach a specific GPS coordinate');
  await clickTextAnywhere(page, 'Create Mission');
  await enableFlutterSemantics(page);
  await waitForAnyText(
    page,
    ['Mission Name', 'Location unavailable', 'Start Mission'],
    timeoutMs * 2,
  );
  recordStep(
    'Walking mission type action reached mission form',
    'Sanctuary -> MissionCreationScreen',
  );

  await gotoRoute(page, '/workout/select-type');
  await clickTextAnywhere(page, 'Resistance Training');
  await page.waitForURL(/#\/workout\/resistance\/select-split/, {
    timeout: timeoutMs,
  });
  await enableFlutterSemantics(page);
  await waitForText(page, 'Choose Your Split');
  recordStep(
    'Workout Resistance Training action reached split route',
    '#/workout/resistance/select-split',
  );

  await clickTextAnywhere(page, 'Upper Body');
  await waitForText(page, 'Workout Settings');
  await clickTextAnywhere(page, '60s');
  await clickTextAnywhere(page, 'Start Workout');
  await waitForText(page, 'Could not start resistance workout.');
  recordStep(
    'Resistance split controls reached guarded start error',
    'Upper Body -> 60s -> Start Workout',
  );

  await gotoRoute(page, '/settings');
  await waitForText(page, 'General Settings');
  await clickTextAnywhere(page, 'Privacy Policy');
  await page.waitForURL(/#\/privacy-policy/, { timeout: timeoutMs });
  await enableFlutterSemantics(page);
  await waitForText(page, 'FlowFit is built for fitness');
  recordStep('Settings Privacy Policy action reached legal route', '#/privacy-policy');

  await gotoRoute(page, '/settings');
  await clickTextAnywhere(page, 'Notification Reminder');
  await page.waitForURL(/#\/notification-settings/, { timeout: timeoutMs });
  await enableFlutterSemantics(page);
  await waitForText(page, 'Stay on track with personalized reminders');
  await clickTextAnywhere(page, 'Water Reminders');
  recordStep(
    'Settings Notification Reminder action reached and toggled preferences',
    '#/notification-settings',
  );

  await gotoRoute(page, '/settings');
  await clickTextAnywhere(page, 'App Integration');
  await page.waitForURL(/#\/app-integration/, { timeout: timeoutMs });
  await enableFlutterSemantics(page);
  await waitForText(page, 'Wearables');
  await waitForText(page, 'Set Up');
  await clickTextAnywhere(page, 'Set Up');
  await page.waitForURL(/#\/wellness-onboarding/, { timeout: timeoutMs });
  await enableFlutterSemantics(page);
  await waitForText(page, 'Next');
  recordStep(
    'Settings App Integration action reached wellness setup',
    '#/wellness-onboarding',
  );

  await gotoRoute(page, '/settings');
  await clickTextAnywhere(page, 'Language');
  await page.waitForURL(/#\/language-settings/, { timeout: timeoutMs });
  await enableFlutterSemantics(page);
  await waitForText(page, 'Select your preferred language');
  await clickTextAnywhere(page, 'Spanish');
  await waitForText(page, 'Spanish');
  recordStep('Settings Language action reached and selected language', '#/language-settings');

  await gotoRoute(page, '/settings');
  await clickTextAnywhere(page, 'Units');
  await page.waitForURL(/#\/unit-settings/, { timeout: timeoutMs });
  await enableFlutterSemantics(page);
  await waitForText(page, 'Measurement System');
  await waitForText(page, 'Individual Units');
  await waitForText(page, 'Distance Kilometers');
  recordStep('Settings Units action reached unit preferences', '#/unit-settings');

  await gotoRoute(page, '/settings');
  await clickTextAnywhere(page, 'Delete Account');
  await page.waitForURL(/#\/delete-account/, { timeout: timeoutMs });
  await enableFlutterSemantics(page);
  await waitForText(page, 'Type DELETE to confirm');
  recordStep('Settings Delete Account action reached guarded deletion surface', '#/delete-account');

  await gotoRoute(page, '/settings');
  await clickTextAnywhere(page, 'Terms of Service');
  await page.waitForURL(/#\/terms-of-service/, { timeout: timeoutMs });
  await enableFlutterSemantics(page);
  await waitForText(page, 'Acceptance of Terms');
  recordStep('Settings Terms of Service action reached legal route', '#/terms-of-service');

  await gotoRoute(page, '/settings');
  await clickTextAnywhere(page, 'Help & Support');
  await page.waitForURL(/#\/help-support/, { timeout: timeoutMs });
  await enableFlutterSemantics(page);
  await waitForText(page, 'Email Support');
  recordStep('Settings Help & Support action reached support route', '#/help-support');

  await gotoRoute(page, '/settings');
  await clickTextAnywhere(page, 'About Us');
  await page.waitForURL(/#\/about-us/, { timeout: timeoutMs });
  await enableFlutterSemantics(page);
  await waitForText(page, 'Meet the team behind FlowFit');
  recordStep('Settings About Us action reached about route', '#/about-us');

  await gotoRoute(page, '/wellness-settings');
  await waitForText(page, 'Wellness Settings');
  await gotoRoute(page, '/wellness-onboarding');
  await waitForText(page, 'Welcome to Wellness Tracker');
  await clickText(page, 'Next');
  await waitForText(page, 'Personalized Recommendations');
  await clickText(page, 'Back');
  await waitForText(page, 'Welcome to Wellness Tracker');
  recordStep(
    'Wellness onboarding carousel Next and Back actions responded',
    '#/wellness-onboarding',
  );

  await gotoRoute(page, '/wellness-settings');
  await waitForText(page, 'Wellness Settings');
  await clickTextAnywhere(page, 'Privacy Policy');
  await page.waitForURL(/#\/privacy-policy/, { timeout: timeoutMs });
  await enableFlutterSemantics(page);
  await waitForText(page, 'FlowFit is built for fitness');
  recordStep(
    'Wellness Settings Privacy Policy action reached legal route',
    '#/privacy-policy',
  );

  await expectRouteText(
    page,
    '/change-password',
    'Current Password',
    'Change password guarded account surface rendered',
  );

  await expectRouteText(
    page,
    '/phone_heart_rate',
    'Watch Heart Rate Data',
    'Phone heart-rate route rendered',
  );

  await expectRouteText(
    page,
    '/buddy-completion',
    'START FIRST MISSION',
    'Buddy completion action surface rendered',
  );

  if (failedRequests.length > 0) {
    throw new Error(`Web app smoke saw ${failedRequests.length} failed network request(s).`);
  }

  const consoleErrors = consoleMessages.filter((message) => message.type === 'error');
  if (consoleErrors.length > 0) {
    throw new Error(`Web app smoke saw ${consoleErrors.length} console error(s).`);
  }

  const summary = {
    generatedAt: new Date().toISOString(),
    baseUrl,
    status: 'PASS',
    summary: {
      pass: steps.length,
      consoleWarnings: consoleMessages.filter((message) => message.type === 'warning').length,
      consoleErrors: consoleErrors.length,
      failedRequests: failedRequests.length,
    },
    steps,
    consoleMessages,
    failedRequests,
  };

  await writeEvidence(summary);

  console.log(
    `FlowFit web app smoke passed: ${steps.length} checks, ` +
      `${summary.summary.consoleWarnings} warning(s), ${summary.summary.consoleErrors} error(s).`,
  );
} catch (error) {
  const screenshotPath = outFile ? `${outFile}.png` : '';
  const currentPage = {
    url: '',
    title: '',
    text: '',
    screenshotPath,
  };

  if (page) {
    currentPage.url = page.url();
    currentPage.title = await page.title().catch(() => '');
    currentPage.text = await page
      .evaluate(() => document.body.innerText)
      .catch(() => '');

    if (screenshotPath) {
      await mkdir(dirname(screenshotPath), { recursive: true });
      await page.screenshot({ path: screenshotPath, fullPage: true }).catch(() => {});
    }
  }

  const consoleErrors = consoleMessages.filter((message) => message.type === 'error');
  await writeEvidence({
    generatedAt: new Date().toISOString(),
    baseUrl,
    status: 'FAIL',
    summary: {
      pass: steps.length,
      consoleWarnings: consoleMessages.filter((message) => message.type === 'warning').length,
      consoleErrors: consoleErrors.length,
      failedRequests: failedRequests.length,
    },
    error: {
      name: error?.name ?? 'Error',
      message: error?.message ?? String(error),
      stack: error?.stack ?? '',
    },
    currentPage,
    steps,
    consoleMessages,
    failedRequests,
  });

  console.error(
    `FlowFit web app smoke failed after ${steps.length} passed check(s): ` +
      `${error?.message ?? error}`,
  );
  throw error;
} finally {
  await browser?.close();
}
