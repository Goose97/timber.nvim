local timber = require("timber")
local helper = require("tests.timber.helper")
local actions = require("timber.actions")

describe("php single log", function()
  before_each(function()
    timber.setup({
      log_templates = {
        default = {
          php = [[error_log("%log_target: " . print_r(%log_target));]],
        },
      },
    })
  end)

  describe("supports variable assignment", function()
    it("supports single assignment", function()
      local input = [[
        <?php
        $fo|o = "bar";
      ]]

      helper.assert_scenario({
        input = input,
        filetype = "php",
        action = function()
          actions.insert_log({ position = "below" })
        end,
  expected = [[
<?php
$foo = "bar";
error_log("$foo: " . print_r($foo));
  ]],
      })

      helper.assert_scenario({
        input = input,
        filetype = "php",
        action = function()
          actions.insert_log({ position = "above" })
        end,
  expected = [[
<?php
  error_log("$foo: " . print_r($foo));
  $foo = "bar";
  ]],
      })
    end)

    it("supports multiple assignment", function()
      helper.assert_scenario({
        input = [[
        <?php
          [$fo|o, $bar] = ["foo", "bar"];
        ]],
        filetype = "php",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
  expected = [[
<?php
  [$foo, $bar] = ["foo", "bar"];
  error_log("$foo: " . print_r($foo));
  error_log("$bar: " . print_r($bar));
  ]],
      })
    end)
  end)

  describe("supports function parameters", function()
    describe("supports function declaration", function()
      it("supports normal parameters", function()
        helper.assert_scenario({
          input = [[
        <?php
            function foo($ba|r) {
                return null;
            }
          ]],
          filetype = "php",
          action = function()
            actions.insert_log({ position = "below" })
          end,
    expected = [[
<?php
    function foo($bar) {
        error_log("$bar: " . print_r($bar));
        return null;
    }
    ]],
        })
      end)

      it("supports multiple parameters", function()
        helper.assert_scenario({
          input = [[
        <?php
            function foo($ba|r, $baz) {
                return null;
            }
          ]],
          filetype = "php",
          action = function()
            vim.cmd("normal! V")
            actions.insert_log({ position = "below" })
          end,
    expected = [[
<?php
    function foo($bar, $baz) {
        error_log("$bar: " . print_r($bar));
        error_log("$baz: " . print_r($baz));
        return null;
    }
    ]],
        })
      end)

      it("supports parameters with type hint", function()
        helper.assert_scenario({
          input = [[
        <?php
            function foo(string $ba|r): string {
                return "bar";
            }
          ]],
          filetype = "php",
          action = function()
            actions.insert_log({ position = "below" })
          end,
    expected = [[
<?php
    function foo(string $bar): string {
        error_log("$bar: " . print_r($bar));
        return "bar";
    }
    ]],
        })
      end)

      it("supports parameters with default values", function()
        helper.assert_scenario({
          input = [[
        <?php
            function foo($ba|r = "default") {
                return $bar;
            }
          ]],
          filetype = "php",
          action = function()
            actions.insert_log({ position = "below" })
          end,
    expected = [[
<?php
    function foo($bar = "default") {
        error_log("$bar: " . print_r($bar));
        return $bar;
    }
    ]],
        })
      end)

      it("supports reference parameters", function()
        helper.assert_scenario({
          input = [[
        <?php
            function foo(&$ba|r) {
                return null;
            }
          ]],
          filetype = "php",
          action = function()
            actions.insert_log({ position = "below" })
          end,
    expected = [[
<?php
    function foo(&$bar) {
        error_log("$bar: " . print_r($bar));
        return null;
    }
    ]],
        })
      end)

      it("supports variadic parameters", function()
        helper.assert_scenario({
          input = [[
        <?php
            function foo(...$ba|r) {
                return null;
            }
          ]],
          filetype = "php",
          action = function()
            actions.insert_log({ position = "below" })
          end,
    expected = [[
<?php
    function foo(...$bar) {
        error_log("$bar: " . print_r($bar));
        return null;
    }
    ]],
        })
      end)
    end)

    it("supports class method", function()
      helper.assert_scenario({
        input = [[
        <?php
          class MyClass {
              public function method($ba|r, $baz) {
                  return null;
              }
          }
        ]],
        filetype = "php",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
  expected = [[
<?php
  class MyClass {
      public function method($bar, $baz) {
          error_log("$bar: " . print_r($bar));
          error_log("$baz: " . print_r($baz));
          return null;
      }
  }
  ]],
      })
    end)

    it("supports anonymous function", function()
      helper.assert_scenario({
        input = [[
        <?php
          $func = function($fo|o, $bar) {
              return $foo + $bar;
          };
        ]],
        filetype = "php",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
  expected = [[
<?php
  $func = function($foo, $bar) {
      error_log("$foo: " . print_r($foo));
      error_log("$bar: " . print_r($bar));
      return $foo + $bar;
  };
  ]],
      })
    end)

    it("supports arrow function", function()
      helper.assert_scenario({
        input = [[
        <?php
          $func = fn($fo|o, $bar) => $foo + $bar;
        ]],
        filetype = "php",
        action = function()
          vim.cmd("normal! V")
          actions.insert_log({ position = "below" })
        end,
  expected = [[
<?php
  $func = fn($foo, $bar) => $foo + $bar;
  error_log("$func: " . print_r($func));
  ]],
      })
    end)
  end)

  it("supports if statement", function()
    helper.assert_scenario({
      input = [[
        <?php
        if ($fo|o > 1 && $bar < $baz) {
            return null;
        } elseif ($bar) {
            return null;
        }
      ]],
      filetype = "php",
      action = function()
        vim.cmd("normal! vap")
        actions.insert_log({ position = "below" })
      end,
expected = [[
<?php
if ($foo > 1 && $bar < $baz) {
    error_log("$foo: " . print_r($foo));
    error_log("$bar: " . print_r($bar));
    error_log("$baz: " . print_r($baz));
    return null;
} elseif ($bar) {
    error_log("$bar: " . print_r($bar));
    return null;
}
]],
    })

    helper.assert_scenario({
      input = [[
        <?php
        if ($fo|o > 1 && $bar < $baz) {
            return null;
        } elseif ($bar) {
            return null;
        }
      ]],
      filetype = "php",
      action = function()
        vim.cmd("normal! vap")
        actions.insert_log({ position = "above" })
      end,
expected = [[
<?php
error_log("$foo: " . print_r($foo));
error_log("$bar: " . print_r($bar));
error_log("$baz: " . print_r($baz));
if ($foo > 1 && $bar < $baz) {
    return null;
} elseif ($bar) {
    return null;
}
]],
    })
  end)

  it("supports match expression", function()
    helper.assert_scenario({
      input = [[
        <?php
        $result = match ($fo|o) {
            $bar => "bar",
            $baz => "baz",
            default => "other",
        };
      ]],
      filetype = "php",
      action = function()
        vim.cmd("normal! vap")
        actions.insert_log({ position = "below" })
      end,
expected = [[
<?php
$result = match ($foo) {
    $bar => "bar",
    $baz => "baz",
    default => "other",
};
error_log("$result: " . print_r($result));
error_log("$foo: " . print_r($foo));
error_log("$bar: " . print_r($bar));
error_log("$baz: " . print_r($baz));
]],
    })

    helper.assert_scenario({
      input = [[
        <?php
        $result = match ($fo|o) {
            1 => "one",
            default => "other",
        };
      ]],
      filetype = "php",
      action = function()
        actions.insert_log({ position = "above" })
      end,
expected = [[
<?php
error_log("$foo: " . print_r($foo));
$result = match ($foo) {
    1 => "one",
    default => "other",
};
]],
    })
  end)

  it("supports ternary expression", function()
    helper.assert_scenario({
      input = [[
        <?php
        $foo = $ba|r >= $baz ? "bar" : "baz";
      ]],
      filetype = "php",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
expected = [[
<?php
$foo = $bar >= $baz ? "bar" : "baz";
error_log("$foo: " . print_r($foo));
error_log("$bar: " . print_r($bar));
error_log("$baz: " . print_r($baz));
]],
    })
  end)

  it("supports foreach loop statement", function()
    helper.assert_scenario({
      input = [[
        <?php
        foreach ($ite|ms as $item) {
            echo $item;
        }
      ]],
      filetype = "php",
      action = function()
        actions.insert_log({ position = "above" })
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
expected = [[
<?php
error_log("$items: " . print_r($items));
foreach ($items as $item) {
    error_log("$item: " . print_r($item));
    error_log("$items: " . print_r($items));
    echo $item;
}
]],
    })

    helper.assert_scenario({
      input = [[
        <?php
        foreach ($ite|ms as $key => $value) {
            echo $value;
        }
      ]],
      filetype = "php",
      action = function()
        actions.insert_log({ position = "above" })
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
expected = [[
<?php
error_log("$items: " . print_r($items));
foreach ($items as $key => $value) {
    error_log("$key: " . print_r($key));
    error_log("$value: " . print_r($value));
    error_log("$items: " . print_r($items));
    echo $value;
}
]],
    })
  end)

  it("supports for loop", function()
    helper.assert_scenario({
      input = [[
        <?php
        for ($i| = 0; $i < 5; $i++) {
            echo $i;
        }
      ]],
      filetype = "php",
      action = function()
        vim.cmd("normal! V")
        actions.insert_log({ position = "below" })
      end,
expected = [[
<?php
for ($i = 0; $i < 5; $i++) {
    error_log("$i: " . print_r($i));
    error_log("$i: " . print_r($i));
    error_log("$i: " . print_r($i));
    echo $i;
}
]],
    })
  end)

  it("supports while loop", function()
    helper.assert_scenario({
      input = [[
        <?php
        $foo = 0;
        while ($fo|o < 5) {
            $foo++;
        }
      ]],
      filetype = "php",
      action = function()
        actions.insert_log({ position = "above" })
        actions.insert_log({ position = "below" })
      end,
expected = [[
<?php
$foo = 0;
error_log("$foo: " . print_r($foo));
while ($foo < 5) {
    error_log("$foo: " . print_r($foo));
    $foo++;
}
]],
    })
  end)

  it("supports switch statement", function()
    helper.assert_scenario({
      input = [[
        <?php
        switch ($fo|o) {
            case $bar:
                echo "bar";
                break;
            case $baz:
                echo "baz";
                break;
            default:
                echo "other";
        }
      ]],
      filetype = "php",
      action = function()
        vim.cmd("normal! vap")
        actions.insert_log({ position = "below" })
      end,
expected = [[
<?php
switch ($foo) {
    case $bar:
        error_log("$bar: " . print_r($bar));
        echo "bar";
        break;
    case $baz:
        error_log("$baz: " . print_r($baz));
        echo "baz";
        break;
    default:
        echo "other";
        error_log("$foo: " . print_r($foo));
}
]],
    })
  end)

  it("supports try-catch statement", function()
    helper.assert_scenario({
      input = [[
        <?php
        try {
            $result = riskyOperation($fo|o);
        } catch (Exception $e) {
            return null;
        }
      ]],
      filetype = "php",
      action = function()
        vim.cmd("normal! vap")
        actions.insert_log({ position = "below" })
      end,
expected = [[
<?php
try {
    error_log("$foo: " . print_r($foo));
    $result = riskyOperation($foo);
} catch (Exception $e) {
    error_log("$e: " . print_r($e));
    return null;
}
]],
    })
  end)

  describe("supports member access expression", function()
    it("supports object property access", function()
      helper.assert_scenario({
        input = [[
        <?php
          $foo = $ba|r->baz;
        ]],
        filetype = "php",
        action = function()
          actions.insert_log({ position = "below" })
        end,
  expected = [[
<?php
  $foo = $bar->baz;
  error_log("$bar: " . print_r($bar));
  ]],
      })

      helper.assert_scenario({
        input = [[
        <?php
          $foo = $bar->ba|z;
        ]],
        filetype = "php",
        action = function()
          actions.insert_log({ position = "below" })
        end,
  expected = [[
<?php
  $foo = $bar->baz;
  error_log("$bar->baz: " . print_r($bar->baz));
  ]],
      })
    end)

    it("supports array access", function()
      helper.assert_scenario({
        input = [[
        <?php
          $foo = $ba|r["baz"];
        ]],
        filetype = "php",
        action = function()
          actions.insert_log({ position = "below" })
        end,
  expected = [[
<?php
  $foo = $bar["baz"];
  error_log("$bar: " . print_r($bar));
  ]],
      })

      helper.assert_scenario({
        input = [[
        <?php
          $foo = $bar["ba|z"];
        ]],
        filetype = "php",
        action = function()
          actions.insert_log({ position = "below" })
        end,
  expected = [[
<?php
  $foo = $bar["baz"];
  error_log("$bar["baz"]: " . print_r($bar["baz"]));
  ]],
      })
    end)

    it("supports static member access", function()
      helper.assert_scenario({
        input = [[
        <?php
          $foo = MyClass::$ba|r;
        ]],
        filetype = "php",
        action = function()
          actions.insert_log({ position = "below" })
        end,
  expected = [[
<?php
  $foo = MyClass::$bar;
  error_log("MyClass::$bar: " . print_r(MyClass::$bar));
  ]],
      })
    end)
  end)

  describe("supports function call", function()
    it("supports normal argument", function()
      helper.assert_scenario({
        input = [[
        <?php
          foo(
              $ba|r,
              $baz
          );
        ]],
        filetype = "php",
        action = function()
          vim.cmd("normal! vap")
          actions.insert_log({ position = "below" })
        end,
  expected = [[
<?php
  foo(
      $bar,
      $baz
  );
  error_log("$bar: " . print_r($bar));
  error_log("$baz: " . print_r($baz));
  ]],
      })
    end)

    it("supports named argument", function()
      helper.assert_scenario({
        input = [[
        <?php
          foo(
              bar: $ba|r,
              baz: $baz
          );
        ]],
        filetype = "php",
        action = function()
          vim.cmd("normal! vap")
          actions.insert_log({ position = "below" })
        end,
  expected = [[
<?php
  foo(
      bar: $bar,
      baz: $baz
  );
  error_log("$bar: " . print_r($bar));
  error_log("$baz: " . print_r($baz));
  ]],
      })
    end)

    it("supports method call chains", function()
      helper.assert_scenario({
        input = [[
        <?php
          $result = $client->metricTaxonomies()->get("general.total_placements");
        ]],
        filetype = "php",
        action = function()
          vim.cmd("normal! ^f>ll")  -- Move to "metricTaxonomies"
          actions.insert_log({ position = "below" })
        end,
  expected = [[
<?php
  $result = $client->metricTaxonomies()->get("general.total_placements");
  error_log("$client->metricTaxonomies(): " . print_r($client->metricTaxonomies()));
  ]],
      })

      helper.assert_scenario({
        input = [[
        <?php
          $result = $client->metricTaxonomies()->get("general.total_placements");
        ]],
        filetype = "php",
        action = function()
          vim.cmd("normal! ^fc")  -- Move to "$client"
          actions.insert_log({ position = "below" })
        end,
  expected = [[
<?php
  $result = $client->metricTaxonomies()->get("general.total_placements");
  error_log("$client: " . print_r($client));
  ]],
      })
    end)

    it("supports regular function calls", function()
      helper.assert_scenario({
        input = [[
        <?php
          $result = strtoupper($text);
        ]],
        filetype = "php",
        action = function()
          vim.cmd("normal! ^ft")  -- Move to "strtoupper"
          actions.insert_log({ position = "below" })
        end,
  expected = [[
<?php
  $result = strtoupper($text);
  error_log("strtoupper($text): " . print_r(strtoupper($text)));
  ]],
      })
    end)

    it("supports static method calls", function()
      helper.assert_scenario({
        input = [[
        <?php
          $result = MyClass::staticMethod($arg);
        ]],
        filetype = "php",
        action = function()
          vim.cmd("normal! ^fM")  -- Move to "MyClass"
          actions.insert_log({ position = "below" })
        end,
  expected = [[
<?php
  $result = MyClass::staticMethod($arg);
  error_log("MyClass::staticMethod($arg): " . print_r(MyClass::staticMethod($arg)));
  ]],
      })
    end)
  end)
end)

describe("php batch log", function()
  it("supports batch log", function()
    timber.setup({
      batch_log_templates = {
        default = {
          php = [[error_log(%repeat<"%log_target: " . print_r(%log_target)>< . "\n" . >);]],
        },
      },
    })

    helper.assert_scenario({
      input = [[
        <?php
        $fo|o = $bar + $baz;
      ]],
      filetype = "php",
      action = function()
        vim.cmd("normal! V")
        actions.add_log_targets_to_batch()
        actions.insert_batch_log()
      end,
expected = [[
<?php
$foo = $bar + $baz;
error_log("$foo: " . print_r($foo) . "\n" . "$bar: " . print_r($bar) . "\n" . "$baz: " . print_r($baz));
]],
    })
  end)
end)
