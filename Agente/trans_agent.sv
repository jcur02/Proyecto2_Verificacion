`include "uvm_macros.svh"
import uvm_pkg::*;

class trans_agent extends uvm_agent;
  `uvm_component_utils(trans_agent)

    // constructor
  function new(string name = "trans_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  uvm_sequencer #(trans_item)	sequencer;
  trans_driver    driver;
  trans_monitor   monitor;

  // build phase
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sequencer = uvm_sequencer#(trans_item)::type_id::create("sequencer", this);
    driver    = trans_driver::type_id::create("driver", this);
    monitor   = trans_monitor::type_id::create("monitor", this);
  endfunction

    // connect phase
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction

endclass