`include "uvm_macros.svh"
import uvm_pkg::*;

class trans_env extends uvm_env;
  `uvm_component_utils(trans_env)
    // constructor
  function new(string name = "trans_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  trans_agent agent;
  trans_scoreboard scoreboard;
  
  // build phase
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    scoreboard = trans_scoreboard::type_id::create("scoreboard", this);
    agent = trans_agent::type_id::create("agent", this);
  endfunction

    // connect phase
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.monitor.ap.connect(scoreboard.mon_imp);
  endfunction

endclass