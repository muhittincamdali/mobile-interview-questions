// Code from the answers in questions/react-native, run by the tests in ../test. Each test name
// starts with the ID of the question it checks.

/**
 * RN-009: a reducer returns a new object for every change and the same object when nothing
 * changed, so React can compare with Object.is and skip the render.
 *
 * @param {{ items: { id: string, done: boolean }[], filter: string }} state
 * @param {{ type: 'toggle', id: string } | { type: 'filter', value: string }} action
 */
export function todosReducer(state, action) {
  switch (action.type) {
    case 'toggle': {
      if (!state.items.some((item) => item.id === action.id)) return state;
      return {
        ...state,
        items: state.items.map((item) => (item.id === action.id ? { ...item, done: !item.done } : item)),
      };
    }
    case 'filter':
      return action.value === state.filter ? state : { ...state, filter: action.value };
    default:
      return state;
  }
}

/**
 * RN-010: calls `fn` once the calls have stopped for `waitMs` milliseconds, with the last
 * arguments. `cancel()` drops a pending call; `flush()` runs it now.
 *
 * @template {unknown[]} Args
 * @param {(...args: Args) => void} fn
 * @param {number} waitMs
 */
export function debounce(fn, waitMs) {
  if (!Number.isFinite(waitMs) || waitMs < 0) throw new RangeError('waitMs must be a finite number >= 0');
  /** @type {ReturnType<typeof setTimeout> | undefined} */
  let timer;
  /** @type {Args | undefined} */
  let pending;

  /** @param {Args} args */
  const debounced = (...args) => {
    pending = args;
    clearTimeout(timer);
    timer = setTimeout(() => {
      timer = undefined;
      const call = pending;
      pending = undefined;
      if (call) fn(...call);
    }, waitMs);
  };
  debounced.cancel = () => {
    clearTimeout(timer);
    timer = undefined;
    pending = undefined;
  };
  debounced.flush = () => {
    if (!pending) return;
    const call = pending;
    debounced.cancel();
    fn(...call);
  };
  return debounced;
}

/**
 * RN-007: runs `task` for each item one after another, unlike `forEach`, which does not wait.
 *
 * @template T, R
 * @param {T[]} items
 * @param {(item: T) => Promise<R>} task
 * @returns {Promise<R[]>}
 */
export async function inSequence(items, task) {
  const results = [];
  for (const item of items) results.push(await task(item));
  return results;
}

/**
 * RN-012: fetches JSON and gives up after `timeoutMs`, or earlier when the caller's signal aborts
 * (for example when a screen unmounts).
 *
 * @param {string} url
 * @param {{ timeoutMs?: number, signal?: AbortSignal }} [options]
 */
export async function fetchJson(url, { timeoutMs = 10_000, signal } = {}) {
  const timeout = AbortSignal.timeout(timeoutMs);
  const combined = signal ? AbortSignal.any([signal, timeout]) : timeout;
  const response = await fetch(url, { signal: combined });
  if (!response.ok) throw new Error(`HTTP ${response.status}`);
  return response.json();
}
