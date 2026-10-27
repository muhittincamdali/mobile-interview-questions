import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { describe, test } from 'node:test';

import { debounce, fetchJson, inSequence, todosReducer } from '../src/answers.mjs';

// Checks the answers in questions/react-native/javascript.md.

describe('JavaScript answers', () => {
  test('RN-001: synchronous code, then microtasks, then timers', async () => {
    const order = [];
    const done = new Promise((resolve) => {
      setTimeout(() => {
        order.push('setTimeout');
        resolve();
      }, 0);
    });
    Promise.resolve().then(() => order.push('promise.then'));
    queueMicrotask(() => order.push('queueMicrotask'));
    (async () => {
      order.push('async function body');
      await null;
      order.push('after await');
    })();
    order.push('synchronous');
    await done;
    assert.deepEqual(order, ['async function body', 'synchronous', 'promise.then', 'queueMicrotask', 'after await', 'setTimeout']);
  });

  test('RN-002: var shares one binding across loop iterations, let creates one per iteration', () => {
    const withVar = [];
    for (var i = 0; i < 3; i++) withVar.push(() => i);
    const withLet = [];
    for (let j = 0; j < 3; j++) withLet.push(() => j);
    assert.deepEqual(withVar.map((read) => read()), [3, 3, 3]);
    assert.deepEqual(withLet.map((read) => read()), [0, 1, 2]);
  });

  test('RN-003: a detached method loses this; an arrow function keeps the outer this', () => {
    class Counter {
      count = 0;
      increment() {
        this.count += 1;
        return this.count;
      }
      incrementArrow = () => {
        this.count += 1;
        return this.count;
      };
    }
    const counter = new Counter();
    const { increment, incrementArrow } = counter;
    assert.throws(() => increment(), TypeError, 'class bodies are strict, so this is undefined');
    assert.equal(incrementArrow(), 1);
    assert.equal(increment.bind(counter)(), 2);
  });

  test('RN-004: == converts types, === does not, and Object.is handles NaN and -0', () => {
    assert.equal(0 == '', true);
    assert.equal(null == undefined, true);
    assert.equal(0 === '', false);
    assert.equal(NaN === NaN, false);
    assert.equal(Object.is(NaN, NaN), true);
    assert.equal(0 === -0, true);
    assert.equal(Object.is(0, -0), false);
    assert.equal({} === {}, false, 'objects compare by reference');
  });

  test('RN-005: ?? only replaces null and undefined, || replaces every falsy value', () => {
    const settings = { volume: 0, name: '', theme: null };
    assert.equal(settings.volume || 50, 50);
    assert.equal(settings.volume ?? 50, 0);
    assert.equal(settings.name ?? 'Guest', '');
    assert.equal(settings.theme ?? 'light', 'light');
    assert.equal(settings.profile?.avatar?.url, undefined);
  });

  test('RN-006: all rejects on the first failure, allSettled reports every result, any takes the first success', async () => {
    const ok = (value, ms) => new Promise((resolve) => setTimeout(() => resolve(value), ms));
    const fail = (reason, ms) => new Promise((_, reject) => setTimeout(() => reject(new Error(reason)), ms));

    await assert.rejects(Promise.all([ok('a', 5), fail('b', 1)]), /b/);
    const settled = await Promise.allSettled([ok('a', 1), fail('b', 1)]);
    assert.deepEqual(settled.map((result) => result.status), ['fulfilled', 'rejected']);
    assert.equal(await Promise.any([fail('x', 1), ok('first success', 5)]), 'first success');
    await assert.rejects(Promise.any([fail('x', 1), fail('y', 2)]), AggregateError);
    assert.equal(await Promise.race([ok('slow', 20), ok('fast', 1)]), 'fast');
  });

  test('RN-007: forEach does not await async callbacks; for...of does', async () => {
    const log = [];
    const save = (item) => new Promise((resolve) => setTimeout(() => resolve(log.push(item)), 30 - item * 10));

    [1, 2, 3].forEach(async (item) => {
      await save(item);
    });
    assert.deepEqual(log, [], 'forEach returned before any save finished');
    await new Promise((resolve) => setTimeout(resolve, 60));
    assert.deepEqual(log, [3, 2, 1], 'the saves ran in parallel and finished out of order');

    log.length = 0;
    await inSequence([1, 2, 3], save);
    assert.deepEqual(log, [1, 2, 3]);
  });

  test('RN-008: sort compares strings by default and sorts in place; toSorted copies', () => {
    const numbers = [10, 9, 1, 100];
    assert.deepEqual([...numbers].sort(), [1, 10, 100, 9]);
    assert.deepEqual(numbers.toSorted((a, b) => a - b), [1, 9, 10, 100]);
    assert.deepEqual(numbers, [10, 9, 1, 100], 'toSorted left the original alone');
    numbers.sort((a, b) => a - b);
    assert.deepEqual(numbers, [1, 9, 10, 100], 'sort changed the array itself');
  });

  test('RN-009: a reducer returns new objects for changes and the same object for no-ops', () => {
    const state = Object.freeze({
      filter: 'all',
      items: Object.freeze([Object.freeze({ id: 'a', done: false }), Object.freeze({ id: 'b', done: true })]),
    });

    const toggled = todosReducer(state, { type: 'toggle', id: 'a' });
    assert.notEqual(toggled, state);
    assert.notEqual(toggled.items, state.items);
    assert.equal(toggled.items[0].done, true);
    assert.equal(toggled.items[1], state.items[1], 'untouched items keep their identity, so memoized rows skip rendering');
    assert.equal(state.items[0].done, false, 'the old state was not mutated (it is frozen)');

    assert.equal(todosReducer(state, { type: 'toggle', id: 'missing' }), state);
    assert.equal(todosReducer(state, { type: 'filter', value: 'all' }), state, 'Object.is(next, prev) lets React bail out');
  });
});

describe('Debounce (RN-010)', () => {
  test('RN-010: debounce calls once with the last arguments after the calls stop', (context) => {
    context.mock.timers.enable({ apis: ['setTimeout'] });
    const calls = [];
    const search = debounce((query) => calls.push(query), 300);

    search('r');
    context.mock.timers.tick(100);
    search('re');
    context.mock.timers.tick(100);
    search('react');
    context.mock.timers.tick(299);
    assert.deepEqual(calls, []);
    context.mock.timers.tick(1);
    assert.deepEqual(calls, ['react']);

    search('native');
    search.cancel();
    context.mock.timers.tick(1_000);
    assert.deepEqual(calls, ['react'], 'cancel() dropped the pending call, as on unmount');

    search('flushed');
    search.flush();
    assert.deepEqual(calls, ['react', 'flushed']);
    context.mock.timers.tick(1_000);
    assert.deepEqual(calls, ['react', 'flushed'], 'flush() does not call twice');
  });

  test('RN-010: debounce rejects a wait that is not a finite non-negative number', () => {
    for (const wait of [Number.NaN, -1, Number.POSITIVE_INFINITY]) {
      assert.throws(() => debounce(() => {}, wait), RangeError);
    }
  });
});

describe('Cancelling requests (RN-012)', () => {
  /** Starts a server that answers /fast at once and never answers /slow. */
  async function withServer(run) {
    const server = createServer((request, response) => {
      if (request.url === '/fast') {
        response.setHeader('content-type', 'application/json');
        response.end('{"ok":true}');
      } else if (request.url === '/missing') {
        response.statusCode = 404;
        response.end();
      }
      // /slow: no answer, like a stalled network
    });
    await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
    const { port } = server.address();
    try {
      await run(`http://127.0.0.1:${port}`);
    } finally {
      server.closeAllConnections();
      await new Promise((resolve) => server.close(resolve));
    }
  }

  test('RN-012: AbortController cancels a fetch, and a timeout signal stops a stalled one', async () => {
    await withServer(async (base) => {
      assert.deepEqual(await fetchJson(`${base}/fast`), { ok: true });
      await assert.rejects(fetchJson(`${base}/missing`), /HTTP 404/, 'fetch resolves for 404; the helper checks response.ok');

      const controller = new AbortController();
      const request = fetchJson(`${base}/slow`, { signal: controller.signal });
      controller.abort();
      await assert.rejects(request, { name: 'AbortError' });

      await assert.rejects(fetchJson(`${base}/slow`, { timeoutMs: 50 }), { name: 'TimeoutError' });
    });
  });
});

