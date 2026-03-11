/**
 * Welsh Vocabulary Quiz - Application Logic
 * Refactored for better organization and maintainability.
 */

// ─── Constants & State ────────────────────────────────────────────────────────

const SR_KEY = 'welsh_sr_piles';
const STATE_KEY = 'welsh_state';
const MASTERY_KEY = 'welsh_mastered_units';
const TS_KEY = 'welsh_sr_timestamps';

let ALL_VOCAB = [];
let srPiles = {};
let srTimestamps = {};
let deck = [];
let currentIndex = 0;
let isFlipped = false;
let direction = 'en-cy';
let typingMode = false;
let activeUnit = null;
let lang = 'en';

// ─── Storage Helpers ──────────────────────────────────────────────────────────

const storage = {
  get(key, fallback = null) {
    try {
      return JSON.parse(localStorage.getItem(key)) ?? fallback;
    } catch {
      return fallback;
    }
  },
  set(key, value) {
    try {
      localStorage.setItem(key, JSON.stringify(value));
    } catch (e) {
      console.warn('storage.set failed:', key, e);
    }
  },
  remove(key) {
    try {
      localStorage.removeItem(key);
    } catch (e) {
      console.warn('storage.remove failed:', key, e);
    }
  }
};

function loadSR() { return storage.get(SR_KEY, {}); }
function saveSR(sr) { storage.set(SR_KEY, sr); }
function loadState() { return storage.get(STATE_KEY, {}); }
function loadMastered() { return new Set(storage.get(MASTERY_KEY, [])); }
function saveMastered(s) { storage.set(MASTERY_KEY, [...s]); }
function loadTimestamps() { return storage.get(TS_KEY, {}); }
function saveTimestamps() { storage.set(TS_KEY, srTimestamps); }

function saveState() {
  storage.set(STATE_KEY, {
    unit: activeUnit,
    direction,
    currentIndex,
    deckIndices: deck.map(c => c._idx)
  });
}

function clearAllData() {
  if (!confirm(t('confirmClear'))) return;
  storage.remove(SR_KEY);
  storage.remove(STATE_KEY);
  storage.remove(MASTERY_KEY);
  storage.remove(TS_KEY);
  srPiles = {};
  srTimestamps = {};
  activeUnit = getUnits()[0] || null;
  direction = 'en-cy';
  rebuildDeck();
  updateDirectionUI();
  buildUnitBar();
  updateCard();
  renderSRStats();
}

// ─── Internationalization (i18n) ──────────────────────────────────────────────

const TRANSLATIONS = {
  en: {
    title: 'Welsh <span>Vocabulary</span> Quiz',
    subtitle: '908 words · Flip to reveal',
    langToggle: 'Cy',
    dirEW: 'English → Welsh',
    dirWE: 'Welsh → English',
    dirLabel: 'Direction',
    modeLabel: 'Mode',
    modeFlip: 'Flip cards',
    modeType: 'Typing',
    flipCue: 'tap to flip',
    typingPlaceholder: 'Type your answer…',
    check: 'Check',
    howDidYou: 'How did you do?',
    hard: 'Hard',
    okay: 'Okay',
    gotIt: 'Got it',
    hint: 'Hint',
    shuffle: '⇌ Shuffle',
    reset: '↺ Reset',
    daIawn: 'Da iawn!',
    completedSet: "You've been through all the cards in this set.",
    reviewWeak: 'Retry difficult words',
    startAgain: 'Start again',
    allKnown: 'All cards marked as Got it!',
    clearProgress: 'Clear all progress',
    kbFlip: 'flip',
    cardLangEn: 'English',
    cardLangCy: 'Welsh',
    startsWith: 'Starts with: ',
    correct: 'Correct!',
    notQuite: 'Not quite — the answer is: ',
    confirmClear: 'Clear all progress and ratings? This cannot be undone.',
    unitLabel: 'Unit',
    pileHard: 'Hard',
    pileOkay: 'Okay',
    pileKnown: 'Known',
    masteryUnit: '',
    masteryTitle: "Wedi'i feistroli!",
    masteryBody: "You've marked every word in this set as <strong>Got it</strong>. Da iawn ti — you've mastered it for now!",
    masteryClose: 'Ardderchog! ✓',
    errorLoad: 'Failed to load vocabulary.json',
    loading: 'Loading…',
  },
  cy: {
    title: 'Cwis <span>Geirfa</span> Cymraeg',
    subtitle: '908 gair · Cliciwch i droi',
    langToggle: 'En',
    dirEW: 'Saesneg → Cymraeg',
    dirWE: 'Cymraeg → Saesneg',
    dirLabel: 'Cyfeiriad',
    modeLabel: 'Modd',
    modeFlip: 'Cardiau troi',
    modeType: 'Teipio',
    flipCue: 'tapiwch i droi',
    typingPlaceholder: 'Teipiwch eich ateb…',
    check: 'Gwirio',
    howDidYou: 'Sut wnaethoch chi?',
    hard: 'Anodd',
    okay: 'Iawn',
    gotIt: 'Wedi dysgu',
    hint: 'Awgrym',
    shuffle: '⇌ Cymysgu',
    reset: '↺ Ailosod',
    daIawn: 'Da iawn!',
    completedSet: 'Rydych chi wedi gweld pob carden yn y set hon.',
    reviewWeak: 'Ailgynnig geiriau anodd',
    startAgain: 'Dechrau eto',
    allKnown: 'Pob carden wedi\'i marcio fel Wedi dysgu!',
    clearProgress: 'Dileu pob cynnydd',
    kbFlip: 'troi',
    cardLangEn: 'Saesneg',
    cardLangCy: 'Cymraeg',
    startsWith: 'Yn dechrau â: ',
    correct: 'Cywir!',
    notQuite: 'Nid yn iawn — yr ateb yw: ',
    confirmClear: 'Dileu pob cynnydd a sgôr? Ni ellir dadwneud hyn.',
    unitLabel: 'Uned',
    pileHard: 'Anodd',
    pileOkay: 'Iawn',
    pileKnown: 'Wedi dysgu',
    masteryUnit: '',
    masteryTitle: "Wedi'i feistroli!",
    masteryBody: "Rydych chi wedi marcio pob gair yn y set hon fel <strong>Wedi dysgu</strong>. Da iawn ti!",
    masteryClose: 'Ardderchog! ✓',
    errorLoad: 'Methwyd â llwytho vocabulary.json',
    loading: 'Yn llwytho…',
  }
};

function t(key) {
  return (TRANSLATIONS[lang]?.[key] !== undefined) ? TRANSLATIONS[lang][key] : (TRANSLATIONS.en[key] || key);
}

function applyLang() {
  document.querySelectorAll('[data-i18n]').forEach(el => { el.innerHTML = t(el.dataset.i18n); });
  document.querySelectorAll('[data-i18n-placeholder]').forEach(el => { el.placeholder = t(el.dataset.i18nPlaceholder); });
  document.getElementById('langToggle').textContent = t('langToggle');
  document.title = lang === 'cy' ? 'Cwis Geirfa Cymraeg' : 'Welsh Vocabulary Quiz';
  document.documentElement.lang = lang === 'cy' ? 'cy' : 'en';
  updateCardLangLabels();
  updateWordCount();
  if (ALL_VOCAB.length > 0) refreshUnitBar();
}

function toggleLang() {
  lang = lang === 'en' ? 'cy' : 'en';
  applyLang();
}

// ─── Core Logic (Deck & Mastery) ──────────────────────────────────────────────

async function loadVocab() {
  try {
    const res = await fetch('vocabulary.json');
    if (!res.ok) throw new Error('HTTP ' + res.status);
    const raw = await res.json();
    ALL_VOCAB = raw.map(v => ({
      e: v.word_english,
      c: v.word_welsh,
      g: v.category,
      l: v.level,
      u: v.unit
    }));
    init();
  } catch (err) {
    document.getElementById('frontWord').textContent = t('errorLoad');
    document.getElementById('frontHint').textContent = 'Error';
    console.error('vocab load error:', err);
  }
}

function getUnits() {
  const units = [...new Set(ALL_VOCAB.map(v => v.u))];
  return units.sort((a, b) => {
    const na = parseInt(a), nb = parseInt(b);
    if (!isNaN(na) && !isNaN(nb)) return na - nb;
    if (!isNaN(na)) return -1;
    if (!isNaN(nb)) return 1;
    return a.localeCompare(b);
  });
}

function matchUnit(item) { return item.u === activeUnit; }

function cardKey(card) { return String(card._idx); }

function rebuildDeck() {
  const base = ALL_VOCAB
    .map((v, i) => ({ ...v, _idx: i }))
    .filter(v => matchUnit(v));
  const piles = [[], [], []];
  base.forEach(card => { piles[srPiles[cardKey(card)] ?? 0].push(card); });
  deck = [...piles[0], ...piles[1], ...piles[2]];
  currentIndex = 0;
}

function getUnitMasteryState(unit) {
  const words = ALL_VOCAB.map((v, i) => ({ ...v, _idx: i })).filter(v => v.u === unit);
  if (words.length === 0) return 'none';
  const known = words.filter(c => (srPiles[cardKey(c)] ?? 0) === 2).length;
  const rated = words.filter(c => srPiles[cardKey(c)] !== undefined).length;
  if (known === words.length) return 'mastered';
  if (rated > 0) return 'partial';
  return 'none';
}

function normalise(s) {
  return s.trim().toLowerCase().replace(/\(.*?\)/g, '').replace(/[.,;!?]/g, '').replace(/\s+/g, ' ').trim();
}

function welshFirstLetter(str) {
  const s = str.trim();
  if (!s) return '';
  const digraphs = ['ch', 'dd', 'ff', 'ng', 'll', 'ph', 'rh', 'th'];
  const lower = s.toLowerCase();
  for (const dg of digraphs) { if (lower.startsWith(dg)) return s.slice(0, 2).toUpperCase(); }
  return s[0].toUpperCase();
}

// ─── UI Updates & Rendering ───────────────────────────────────────────────────

function getCatClass(cat) {
  if (cat === 'feminine noun') return 'cat-feminine';
  if (cat === 'masculine noun') return 'cat-masculine';
  if (cat === 'adjective') return 'cat-adjective';
  if (cat === 'verb') return 'cat-verb';
  return 'cat-other';
}

function renderSRStats() {
  const base = activeUnit === null
    ? deck.map((v, i) => ({ ...v, _idx: v._idx }))
    : ALL_VOCAB.map((v, i) => ({ ...v, _idx: i })).filter(v => matchUnit(v));
  const hard = base.filter(c => srPiles[cardKey(c)] === 0).length;
  const okay = base.filter(c => srPiles[cardKey(c)] === 1).length;
  const known = base.filter(c => srPiles[cardKey(c)] === 2).length;

  document.getElementById('srHard').textContent = hard;
  document.getElementById('srOkay').textContent = okay;
  document.getElementById('srKnown').textContent = known;

  document.getElementById('srStatHard').dataset.count = hard;
  document.getElementById('srStatOkay').dataset.count = okay;
  document.getElementById('srStatKnown').dataset.count = known;

  const pileLabels = [t('hard'), t('okay'), t('gotIt')];
  const counts = [hard, okay, known];
  const ids = ['srStatHard', 'srStatOkay', 'srStatKnown'];

  ids.forEach((id, i) => {
    document.getElementById(id).title = counts[i] > 0
      ? (lang === 'cy' ? `Adolygu ${counts[i]} gair ${pileLabels[i].toLowerCase()}` : `Review ${counts[i]} ${pileLabels[i].toLowerCase()} word${counts[i] !== 1 ? 's' : ''}`)
      : '';
  });
}

function showRatingButtons(show) {
  document.getElementById('ratingRow').style.display = show ? 'flex' : 'none';
}

function updateWordCount() {
  const count = ALL_VOCAB.length;
  const el = document.getElementById('wordCountLabel');
  if (el) el.textContent = count + (lang === 'cy' ? ' gair' : ' words');
}

function updateDirectionUI() {
  document.getElementById('dirEW').classList.toggle('active', direction === 'en-cy');
  document.getElementById('dirWE').classList.toggle('active', direction === 'cy-en');
}

function updateCardLangLabels() {
  const isCyFront = direction === 'cy-en';
  document.getElementById('frontHint').textContent = isCyFront ? t('cardLangCy') : t('cardLangEn');
  document.getElementById('backHint').textContent = isCyFront ? t('cardLangEn') : t('cardLangCy');
  document.getElementById('typingLang').textContent = isCyFront ? t('cardLangEn') : t('cardLangCy');
}

function updateProgress() {
  const total = deck.length;
  const pct = total > 0 ? Math.round((currentIndex / total) * 100) : 0;
  const pos = Math.min(currentIndex + 1, total);
  document.getElementById('progressLabel').textContent = 'Card ' + pos + ' of ' + total;
  document.getElementById('progressPct').textContent = pct + '%';
  document.getElementById('progressFill').style.width = pct + '%';
}

function renderCard() {
  if (currentIndex >= deck.length) return;
  const card = deck[currentIndex];
  const pile = srPiles[cardKey(card)] ?? 0;
  const pileBadge = document.getElementById('pileBadge');
  const isRated = srPiles[cardKey(card)] !== undefined;

  if (!isRated) {
    pileBadge.textContent = '';
    pileBadge.className = 'pile-badge pile-0';
  } else {
    const labels = [t('pileHard'), t('pileOkay'), t('pileKnown')];
    const classes = ['pile-0-rated', 'pile-1', 'pile-2'];
    pileBadge.textContent = labels[pile];
    pileBadge.className = 'pile-badge ' + classes[pile];
  }

  if (direction === 'en-cy') {
    document.getElementById('frontHint').textContent = t('cardLangEn');
    document.getElementById('frontWord').textContent = card.e;
    document.getElementById('backHint').textContent = t('cardLangCy');
    document.getElementById('backWord').textContent = card.c;
  } else {
    document.getElementById('frontHint').textContent = t('cardLangCy');
    document.getElementById('frontWord').textContent = card.c;
    document.getElementById('backHint').textContent = t('cardLangEn');
    document.getElementById('backWord').textContent = card.e;
  }
  document.getElementById('backCategory').textContent = card.g;
  document.getElementById('cardBack').className = 'card-face card-back ' + getCatClass(card.g);
}

function renderTypingCard() {
  if (currentIndex >= deck.length) return;
  const card = deck[currentIndex];
  document.getElementById('typingPrompt').textContent = direction === 'en-cy' ? card.e : card.c;
  document.getElementById('typingInput').value = '';
  document.getElementById('typingInput').disabled = false;
  document.getElementById('typingFeedback').textContent = '';
  document.getElementById('typingFeedback').className = 'typing-feedback';
  document.getElementById('typingSubmit').style.display = 'inline-block';
  document.getElementById('typingLang').textContent = direction === 'en-cy' ? t('cardLangCy') : t('cardLangEn');
  document.getElementById('hintText').textContent = '';
  document.getElementById('hintBtn').disabled = false;
  document.getElementById('typingInput').focus();
}

function updateCard() {
  const banner = document.getElementById('completeBanner');
  const cardShell = document.querySelector('.card-shell');
  const typArea = document.getElementById('typingArea');

  if (currentIndex >= deck.length) {
    banner.style.display = 'block';
    cardShell.style.display = 'none';
    typArea.style.display = 'none';
    document.getElementById('hint-row-wrap').style.display = 'none';
    document.getElementById('ratingRow').style.display = 'none';
    const weakCount = deck.filter(v => (srPiles[cardKey(v)] ?? 0) < 2).length;
    const reviewBtn = document.getElementById('reviewWeakBtn');
    if (reviewBtn) {
      reviewBtn.disabled = weakCount === 0;
      reviewBtn.title = weakCount === 0 ? t('allKnown') : weakCount + ' cards to review';
    }
    updateProgress(); saveState(); return;
  }

  banner.style.display = 'none';
  cardShell.style.display = 'block';
  showRatingButtons(false);

  if (typingMode) {
    document.getElementById('cardArea').style.display = 'none';
    typArea.style.display = 'block';
    document.getElementById('hint-row-wrap').style.display = 'none';
    renderTypingCard();
  } else {
    document.getElementById('cardArea').style.display = 'block';
    typArea.style.display = 'none';
    document.getElementById('hint-row-wrap').style.display = 'flex';
    const inner = document.getElementById('cardInner');
    inner.style.transition = 'none';
    inner.classList.remove('flipped');
    isFlipped = false;
    setTimeout(() => inner.style.transition = '', 30);
    document.getElementById('hintText').textContent = '';
    document.getElementById('hintBtn').disabled = false;
    renderCard();
  }

  updateProgress();
  saveState();
}

function unitPillLabel(unit, state) {
  const tick = state === 'mastered' ? ' \u2713' : '';
  const count = ALL_VOCAB.filter(v => v.u === unit).length;
  const lbl = isNaN(parseInt(unit)) ? unit.charAt(0).toUpperCase() + unit.slice(1) : t('unitLabel') + ' ' + unit;
  return lbl + ' (' + count + ')' + tick;
}

function buildUnitBar() {
  const bar = document.getElementById('unitBar');
  bar.innerHTML = '';
  const anyMastered = getUnits().some(u => getUnitMasteryState(u) === 'mastered');
  if (anyMastered) {
    const reviewPill = document.createElement('button');
    reviewPill.className = 'review-pill';
    reviewPill.id = 'unitBarReviewBtn';
    reviewPill.textContent = lang === 'cy' ? 'Adolygu' : 'Review';
    reviewPill.onclick = reviewOldWords;
    bar.appendChild(reviewPill);
  }

  getUnits().forEach(unit => {
    const state = getUnitMasteryState(unit);
    const btn = document.createElement('button');
    let cls = 'unit-btn';
    if (state === 'mastered') cls += ' unit-btn-mastered';
    else if (state === 'partial') cls += ' unit-btn-partial';
    if (activeUnit === unit) cls += ' active';
    btn.className = cls;
    btn.dataset.unit = unit;
    btn.textContent = unitPillLabel(unit, state);
    btn.onclick = () => setUnit(unit, btn);
    bar.appendChild(btn);
  });
}

function refreshUnitBar() {
  const anyMastered = getUnits().some(u => getUnitMasteryState(u) === 'mastered');
  const bar = document.getElementById('unitBar');
  const existing = document.getElementById('unitBarReviewBtn');
  if (anyMastered && !existing) {
    buildUnitBar(); return;
  } else if (!anyMastered && existing) {
    existing.remove();
  } else if (anyMastered && existing) {
    existing.textContent = lang === 'cy' ? 'Adolygu' : 'Review';
  }
  document.querySelectorAll('.unit-btn').forEach(btn => {
    const state = getUnitMasteryState(btn.dataset.unit);
    btn.classList.remove('unit-btn-mastered', 'unit-btn-partial');
    if (state === 'mastered') btn.classList.add('unit-btn-mastered');
    else if (state === 'partial') btn.classList.add('unit-btn-partial');
    btn.textContent = unitPillLabel(btn.dataset.unit, state);
  });
}

function showMasteryCelebration(unit) {
  const label = isNaN(parseInt(unit)) ? unit.charAt(0).toUpperCase() + unit.slice(1) : 'Unit ' + unit;
  const overlay = document.createElement('div');
  overlay.className = 'mastery-overlay';
  overlay.innerHTML = `
    <div class="mastery-card">
      <canvas class="mastery-confetti" id="masteryCanvas"></canvas>
      <div class="mastery-unit">${label}</div>
      <h2>${t('masteryTitle')}</h2>
      <p>${t('masteryBody')}</p>
      <button class="btn-close-mastery" onclick="this.closest('.mastery-overlay').remove()">${t('masteryClose')}</button>
    </div>`;
  document.body.appendChild(overlay);
  overlay.addEventListener('click', e => { if (e.target === overlay) overlay.remove(); });

  const canvas = document.getElementById('masteryCanvas');
  const ctx = canvas.getContext('2d');
  const card = canvas.parentElement;
  canvas.width = card.offsetWidth;
  canvas.height = card.offsetHeight;
  const pieces = Array.from({ length: 60 }, () => ({
    x: Math.random() * canvas.width, y: -10 - Math.random() * 80,
    r: 4 + Math.random() * 5, d: 2 + Math.random() * 3,
    color: ['#1a6b3c', '#c8a84b', '#2471a3', '#b83232', '#7d5fa5'][Math.floor(Math.random() * 5)],
    tilt: Math.random() * 10 - 5, tiltSpeed: 0.1 + Math.random() * 0.2
  }));
  let frame = 0;
  function drawConfetti() {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    pieces.forEach(p => {
      ctx.beginPath();
      ctx.ellipse(p.x, p.y, p.r, p.r * 0.5, p.tilt, 0, Math.PI * 2);
      ctx.fillStyle = p.color; ctx.fill();
      p.y += p.d; p.x += Math.sin(frame * 0.05 + p.tilt) * 0.8; p.tilt += p.tiltSpeed;
    });
    frame++;
    if (frame < 200) requestAnimationFrame(drawConfetti);
    else ctx.clearRect(0, 0, canvas.width, canvas.height);
  }
  drawConfetti();
}

// ─── Event Handlers & Interactivity ───────────────────────────────────────────

function rateCard(pile) {
  if (currentIndex >= deck.length) return;
  const card = deck[currentIndex];
  const key = cardKey(card);
  srPiles[key] = pile;
  if (pile === 2 && !srTimestamps[key]) srTimestamps[key] = Date.now();
  saveSR(srPiles);
  saveTimestamps();
  renderSRStats();
  refreshUnitBar();
  if (pile === 2 && activeUnit !== null) {
    const state = getUnitMasteryState(activeUnit);
    if (state === 'mastered') {
      const celebrated = loadMastered();
      if (!celebrated.has(activeUnit)) {
        celebrated.add(activeUnit);
        saveMastered(celebrated);
        setTimeout(() => showMasteryCelebration(activeUnit), 400);
      }
    }
  }
  advanceCard();
}

function setTypingMode(on) {
  typingMode = on;
  document.getElementById('modeFlip').classList.toggle('active', !on);
  document.getElementById('modeType').classList.toggle('active', on);
  showRatingButtons(false);
  resetTypingArea();
  updateCard();
  saveState();
}

function resetTypingArea() {
  document.getElementById('typingInput').value = '';
  document.getElementById('typingFeedback').textContent = '';
  document.getElementById('typingFeedback').className = 'typing-feedback';
  document.getElementById('typingSubmit').style.display = 'inline-block';
  document.getElementById('typingInput').disabled = false;
}

function checkTyping() {
  if (currentIndex >= deck.length) return;
  const card = deck[currentIndex];
  const answer = direction === 'en-cy' ? card.c : card.e;
  const user = normalise(document.getElementById('typingInput').value);
  const correct = normalise(answer);
  const isOk = correct.split('/').map(s => s.trim()).some(v => v === user);
  const fb = document.getElementById('typingFeedback');
  fb.textContent = isOk ? t('correct') : t('notQuite') + answer;
  fb.className = 'typing-feedback ' + (isOk ? 'correct' : 'wrong');
  document.getElementById('typingInput').disabled = true;
  document.getElementById('typingSubmit').style.display = 'none';
  showRatingButtons(true);
  updateProgress();
  saveState();
}

function setUnit(unit, btn) {
  activeUnit = unit;
  document.querySelectorAll('.unit-btn').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');
  btn.scrollIntoView({ block: 'nearest', inline: 'center', behavior: 'smooth' });
  rebuildDeck();
  renderSRStats();
  updateWordCount();
  if (typingMode) renderTypingCard(); else updateCard();
  saveState();
}

function setDirection(dir) {
  direction = dir;
  updateDirectionUI();
  const inner = document.getElementById('cardInner');
  inner.style.transition = 'none';
  inner.classList.remove('flipped');
  isFlipped = false;
  setTimeout(() => inner.style.transition = '', 30);
  document.getElementById('hintText').textContent = '';
  document.getElementById('hintBtn').disabled = false;
  showRatingButtons(false);
  if (typingMode) renderTypingCard(); else renderCard();
  saveState();
}

function flipCard() {
  if (currentIndex >= deck.length || typingMode) return;
  isFlipped = !isFlipped;
  document.getElementById('cardInner').classList.toggle('flipped', isFlipped);
  showRatingButtons(isFlipped);
}

function advanceCard() { currentIndex++; showRatingButtons(false); updateCard(); }

function shuffle() {
  for (let i = deck.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [deck[i], deck[j]] = [deck[j], deck[i]];
  }
  currentIndex = 0;
  showRatingButtons(false); updateCard();
}

function restart() { rebuildDeck(); showRatingButtons(false); updateCard(); }

function reviewWeak() {
  const base = deck.filter(v => (srPiles[cardKey(v)] ?? 0) < 2);
  if (base.length === 0) return;
  deck = base;
  currentIndex = 0;
  showRatingButtons(false);
  updateCard();
}

function reviewByPile(pile) {
  const base = ALL_VOCAB
    .map((v, i) => ({ ...v, _idx: i }))
    .filter(v => matchUnit(v) && (srPiles[cardKey(v)] ?? 0) === pile);
  if (base.length === 0) return;
  deck = base;
  currentIndex = 0;
  showRatingButtons(false);
  updateCard();
}

function reviewOldWords() {
  const known = ALL_VOCAB
    .map((v, i) => ({ ...v, _idx: i }))
    .filter(v => srPiles[cardKey(v)] === 2 && srTimestamps[cardKey(v)])
    .sort((a, b) => srTimestamps[cardKey(a)] - srTimestamps[cardKey(b)]);
  if (known.length < 1) return;
  const oldest20 = known.slice(0, 20);
  for (let i = oldest20.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [oldest20[i], oldest20[j]] = [oldest20[j], oldest20[i]];
  }
  deck = oldest20.slice(0, 10);
  currentIndex = 0;
  activeUnit = null;
  document.querySelectorAll('.unit-btn').forEach(b => b.classList.remove('active'));
  showRatingButtons(false);
  renderSRStats();
  updateCard();
}

function showHint() {
  if (currentIndex >= deck.length) return;
  const card = deck[currentIndex];
  const answer = direction === 'en-cy' ? card.c : card.e;
  document.getElementById('hintText').textContent = (lang === 'cy' ? 'Yn dechrau â: ' : 'Starts with: ') + welshFirstLetter(answer);
  document.getElementById('hintBtn').disabled = true;
}

function toggleSettings() {
  const panel = document.getElementById('settingsPanel');
  const btn = document.getElementById('settingsToggle');
  const open = panel.style.display === 'none';
  panel.style.display = open ? 'block' : 'none';
  btn.classList.toggle('open', open);
}

// ─── Initialization & Listeners ───────────────────────────────────────────────

function init() {
  const saved = loadState();
  activeUnit = saved.unit || getUnits()[0] || null;
  if (saved.direction) direction = saved.direction;

  srPiles = loadSR();
  srTimestamps = loadTimestamps();

  rebuildDeck();
  buildUnitBar();
  renderSRStats();
  updateDirectionUI();
  updateWordCount();

  if (saved.deckIndices && saved.deckIndices.length === deck.length) {
    const reordered = saved.deckIndices
      .map(idx => ALL_VOCAB[idx] ? { ...ALL_VOCAB[idx], _idx: idx } : null)
      .filter(Boolean);
    if (reordered.length === deck.length) deck = reordered;
    if (saved.currentIndex !== undefined) currentIndex = Math.min(saved.currentIndex, deck.length);
  }

  updateCard();
  applyLang();
  setTimeout(() => {
    const activeBtn = document.querySelector('.unit-btn.active');
    if (activeBtn) activeBtn.scrollIntoView({ block: 'nearest', inline: 'center', behavior: 'smooth' });
  }, 100);
}

document.addEventListener('keydown', e => {
  if (typingMode) return;
  if (e.key === ' ' || e.key === 'ArrowUp' || e.key === 'ArrowDown') {
    e.preventDefault(); flipCard();
  } else if (e.key === '1') { if (isFlipped) rateCard(0); }
  else if (e.key === '2') { if (isFlipped) rateCard(1); }
  else if (e.key === '3') { if (isFlipped) rateCard(2); }
});

// ─── Startup ──────────────────────────────────────────────────────────────────

loadVocab();
