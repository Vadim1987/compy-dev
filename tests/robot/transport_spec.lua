require('model.robot.transport')
require('model.serial.backend_fake')

--- The transport against the fake backend and a hand-driven
--- clock. rx() feeds bridge replies; tick() advances time
--- and pumps updates the way the main loop would.

describe('robot transport', function()
  local backend, serial, t, now

  local errors, faults

  local function tick(dt)
    now = now + (dt or 0.001)
    for _, e in ipairs(serial:update()) do
      errors[#errors + 1] = e
    end
    local f = t:update()
    if f then
      faults[#faults + 1] = f
    end
  end

  local function rx(line)
    backend.sink.bytes(line .. '\r\n')
    tick(0)
  end

  local function connect()
    backend.sink.attach({ name = 'fake' })
    tick(0)
  end

  before_each(function()
    now = 0
    errors = {}
    faults = {}
    backend = FakeBackend.new()
    serial = Serial.new(backend)
    t = RobotTransport.new(serial, function() return now end, 7)
    t:start('console')
  end)

  it('associates on connect', function()
    connect()
    assert.same('!g 7\r', backend.sent[1])
    assert.same('associating', t:state())
    rx('!ok group 7')
    assert.same('ready', t:state())
  end)

  it('retries the association and gives up with a fault',
  function()
    connect()
    for _ = 1, 8 do
      tick(0.031)
    end
    tick(0.031)
    assert.same('idle', t:state())
    assert.same('bridge not answering', faults[#faults])
    assert.same(8, #backend.sent)
  end)

  it('ignores a wrong group confirmation', function()
    connect()
    rx('!ok group 3')
    assert.same('associating', t:state())
  end)

  describe('when ready', function()
    before_each(function()
      connect()
      rx('!ok group 7')
    end)

    it('sends the envelope and completes on the ack',
    function()
      local got
      t:command('M 10 10 500', function(ok, err)
        got = { ok, err }
      end)
      assert.same('COMMAND 1 M 10 10 500\r',
        backend.sent[#backend.sent])
      rx('ACK 1 1')
      assert.same({ true }, got)
      assert.same('ready', t:state())
    end)

    it('reports a refusal', function()
      local got
      t:command('M 10 10 500', function(ok, err)
        got = { ok, err }
      end)
      rx('ACK 1 0')
      assert.same({ false, 'refused' }, got)
    end)

    it('retries the identical line on the timeout', function()
      t:command('M 10 10 500', function() end)
      local first = backend.sent[#backend.sent]
      tick(0.031)
      assert.same(first, backend.sent[#backend.sent])
      assert.same(3, #backend.sent)
    end)

    it('gives up after the tries and reports the timeout',
    function()
      local got
      t:command('M 10 10 500', function(ok, err)
        got = { ok, err }
      end)
      for _ = 1, 9 do
        tick(0.031)
      end
      assert.same({ nil, 'timeout' }, got)
      assert.same('ready', t:state())
    end)

    it('takes one command at a time', function()
      t:command('A', function() end)
      local ok, err = t:command('B', function() end)
      assert.is_nil(ok)
      assert.same('sending', err)
    end)

    it('ignores a stale ack and counts it', function()
      t:command('A', function() end)
      rx('ACK 1 1')
      t:command('B', function() end)
      rx('ACK 1 1')
      assert.same('sending', t:state())
      assert.same(1, t.stale)
      rx('ACK 2 1')
      assert.same('ready', t:state())
    end)

    it('numbers commands across a reconnect without reuse',
    function()
      t:command('A', function() end)
      rx('ACK 1 1')
      backend.sink.detach()
      tick(0)
      connect()
      rx('!ok group 7')
      t:command('B', function() end)
      assert.same('COMMAND 2 B\r',
        backend.sent[#backend.sent])
    end)

    it('fails the outstanding command on a disconnect',
    function()
      local got
      t:command('A', function(ok, err)
        got = { ok, err }
      end)
      backend.sink.detach()
      tick(0)
      assert.same({ nil, 'disconnected' }, got)
      assert.same('idle', t:state())
    end)
  end)
end)
