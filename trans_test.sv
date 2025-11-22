`include "uvm_macros.svh"
import uvm_pkg::*;

class trans_test extends uvm_test;
  `uvm_component_utils(trans_test)
    // constructor
  function new(string name = "trans_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  trans_env env;
  virtual mesh_gnrt_if vif;

  // build phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = trans_env::type_id::create("trans_env", this);
    if (!uvm_config_db#(virtual mesh_gnrt_if)::get(this, "", "vif", vif))
      `uvm_fatal("TEST", "Did not get vif")
      
      uvm_config_db#(virtual mesh_gnrt_if)::set(this, "trans_env.agent.*", "vif", vif);
  endfunction

    // run phase
  virtual task run_phase(uvm_phase phase);
    gen_sequence seq = gen_sequence::type_id::create("seq");
    phase.raise_objection(this);
    apply_reset();
    
    seq.randomize();
    seq.start(env.agent.sequencer);
    repeat (5000) @(posedge vif.clk);
    phase.drop_objection(this);
  endtask
  
  // reset task
  virtual task apply_reset();
    integer k;
    vif.reset <= 1;
    for (k = 0; k < 16; k = k + 1) begin
      vif.pop[k]           <= 1'b0;
      vif.pndng_i_in[k]    <= 1'b0;
      vif.data_out_i_in[k] <= '0;
    end
    repeat(5) @ (posedge vif.clk);
    vif.reset <= 0;
    repeat(10) @ (posedge vif.clk);
  endtask
endclass