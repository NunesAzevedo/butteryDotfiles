local plugins = {
 -- {
 --  "rcarriga/nvim-dap-ui",
 --   event = "VeryLazy",
 --   dependencies = "mfussenegger/nvim-dap",
 --   config = function ()
 --     local dap = require("dap")
 --     local dapui = require("dapui")
 --     dapui.setup()
 --     dap.listeners.after.event_initialized["dapui_config"] = function ()
 --       dapui.open()
 --     end
 --     dap.listeners.before.event_terminater["dapui_config"] = function ()
 --       dapui.close()
 --     end
 --     dap.listeners.before.event_exited["dapui_config"] = function ()
 --       dapui.close()
 --     end
 --   end
 -- },

--  {
--    "jay-babu/mason-nvim-dap.nvim",
--    event = "VeryLazy",
--    dependencies = {
--      "williamboman/mason.nvim",
--      "mfussenegger/nvim-dap",
--    },
--    opts = {
--      handlers = {}
--      ensure_installed = {
--        "codelldb",
--      }
--    },
--  },

--  {
--    "mfussenegger/nvim-dap",
--    config = function (_, _)
--      require("core.utils").load_mappings("dap")
--    end
--  },
}

return plugins
