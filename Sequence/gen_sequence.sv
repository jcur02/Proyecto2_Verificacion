`include "uvm_macros.svh"
import uvm_pkg::*;

class gen_sequence extends uvm_sequence;
  `uvm_object_utils(gen_sequence)
  function new(string name = "gen_sequence");
    super.new(name);
  endfunction

  rand int num_per_terminal[16];

  // cantidad de transacciones por terminal
  constraint c_counts {
    foreach (num_per_terminal[i]) num_per_terminal[i] inside {[3:10]};
  }

  virtual task body();
    int t;
    foreach (num_per_terminal[t]) begin
      for (int k = 0; k < num_per_terminal[t]; k++) begin
        trans_item m_item = trans_item::type_id::create($sformatf("m_item_%0d_%0d", t, k));
        start_item(m_item);
        assert(m_item.randomize() with { sender == t; });
        `uvm_info("SEQ", $sformatf("Generate item from terminal %0d with gap of %0d", t, m_item.send_gap), UVM_LOW)
        finish_item(m_item);
      end
    end
  endtask
endclass