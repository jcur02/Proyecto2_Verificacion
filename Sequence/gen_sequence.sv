`include "uvm_macros.svh"
import uvm_pkg::*;

class gen_sequence extends uvm_sequence;
  `uvm_object_utils(gen_sequence)

    // constructor
  function new(string name = "gen_sequence");
    super.new(name);
  endfunction

  // cantidad de transacciones a generar  
  rand int num;
  
  constraint c1 { num inside {[3:4]}; }

  virtual task body();
    for (int i = 0; i < num; i ++) begin
    	trans_item m_item = trans_item::type_id::create("m_item");
    	start_item(m_item);
    	m_item.randomize();
    	`uvm_info("SEQ", $sformatf("Generate new item: "), UVM_LOW)
    	m_item.print(); // imprimir la transaccion generada
      	finish_item(m_item);
    end
    `uvm_info("SEQ", $sformatf("Done generation of %0d items", num), UVM_LOW)
  endtask
endclass