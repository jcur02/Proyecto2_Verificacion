`include "uvm_macros.svh"
import uvm_pkg::*;

// test que resetea el DUT en medio de tráfico para caso esquina
class trans_test_reset_mid_traffic extends trans_test;
  `uvm_component_utils(trans_test_reset_mid_traffic)

  function new(string name="trans_test_reset_mid_traffic",
               uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    gen_sequence seq;
    gen_sequence seq2;

    phase.raise_objection(this);

    // Reset inicial 
    apply_reset();

    // 1) tráfico random
    seq = gen_sequence::type_id::create("seq");
    assert(seq.randomize());
    fork
      seq.start(env.agent.sequencer);
    join_none

    // 2) llenar un poco la red
    repeat (300) @(posedge vif.clk);  

    // 3) Reset en medio del tráfico
    `uvm_info("TEST", "Aplicando reset en medio del tráfico", UVM_LOW)
    vif.reset <= 1;
    repeat (5) @(posedge vif.clk);
    vif.reset <= 0;
    repeat (5) @(posedge vif.clk);

    // 4) Tráfico después del reset
    seq2 = gen_sequence::type_id::create("seq2");
    assert(seq2.randomize());
    seq2.start(env.agent.sequencer);

    repeat (3000) @(posedge vif.clk);
    phase.drop_objection(this);
  endtask

endclass