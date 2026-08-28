require('model.robot.transport')
require('model.serial.init')
require('model.serial.backend_fake')

--- The machine on its own send stub and hand-driven clock,
--- plus one wiring spec through the real facade tables the
--- way a consumer connects it.

describe('robot transport', function()
  local t, now, sent, faults

  local function tick(dt)
    now = now + (dt or 0.001)
    local f = t:update()
    if f then
      faults[#faults + 1] = f
    end
  end

  before_each(function()
    now = 0
    sent = {}
    faults = {}
    t = RobotTransport.new(function(l)
      sent[#sent + 1] = l
      return true
    end, function() return now end, 7)
  end)

  it('associates on connect', function()
    t:connected()
    assert.same('!g 7\r', sent[1])
    assert.same('associating', t:state())
    t:take('!ok group 7')
    assert.same('ready', t:state())
  end)

  it('retries the association and gives up with a fault',
  function()
    t:connected()
    for _ = 1, 8 do
      tick(0.031)
    end
    assert.same('idle', t:state())
    assert.same('bridge not answering', faults[#faults])
    assert.same(8, #sent)
  end)

  it('ignores a wrong group confirmation', function()
    t:connected()
    t:take('!ok group 3')
    assert.same('associating', t:state())
  end)

  describe('when ready', function()
    before_each(function()
      t:connected()
      t:take('!ok group 7')
    end)

    it('sends the envelope and completes on the ack',
    function()
      local got
      t:command('M 10 10 500', function(ok, err)
        got = { ok, err }
      end)
      assert.same('COMMAND 1 M 10 10 500\r', sent[#sent])
      t:take('ACK 1 1')
      assert.same({ true }, got)
      assert.same('ready', t:state())
    end)

    it('reports a refusal', function()
      local got
      t:command('M 10 10 500', function(ok, err)
        got = { ok, err }
      end)
      t:take('ACK 1 0')
      assert.same({ false, 'refused' }, got)
    end)

    it('retries the identical line on the timeout', function()
      t:command('M 10 10 500', function() end)
      local first = sent[#sent]
      tick(0.031)
      assert.same(first, sent[#sent])
      assert.same(3, #sent)
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
      t:take('ACK 1 1')
      t:command('B', function() end)
      t:take('ACK 1 1')
      assert.same('sending', t:state())
      assert.same(1, t.stale)
      t:take('ACK 2 1')
      assert.same('ready', t:state())
    end)

    it('numbers commands across a reconnect without reuse',
    function()
      t:command('A', function() end)
      t:take('ACK 1 1')
      t:disconnected()
      t:connected()
      t:take('!ok group 7')
      t:command('B', function() end)
      assert.same('COMMAND 2 B\r', sent[#sent])
    end)

    it('fails the outstanding command on a disconnect',
    function()
      local got
      t:command('A', function(ok, err)
        got = { ok, err }
      end)
      t:disconnected()
      assert.same({ nil, 'disconnected' }, got)
      assert.same('idle', t:state())
    end)
  end)
end)

describe('robot transport wired to compy.serial', function()
  it('runs the round through the facade tables', function()
    local backend = FakeBackend.new()
    local serial = Serial.new(backend)
    local cs = serial:table_for('console')
    local now = 0
    local t = RobotTransport.new(cs.send,
      function() return now end, 0)
    cs.onConnect = function() t:connected() end
    cs.onDisconnect = function() t:disconnected() end
    cs.onLine = function(l) t:take(l) end

    backend.sink.attach({ name = 'fake' })
    serial:update()
    assert.same('associating', t:state())
    assert.same('!g 0\r', backend.sent[1])

    backend.sink.bytes('!ok group 0\r\n')
    serial:update()
    assert.same('ready', t:state())

    local got
    t:command('M 10 10 500', function(ok) got = ok end)
    backend.sink.bytes('ACK 1 1\r\n')
    serial:update()
    assert.is_true(got)
  end)
end)
