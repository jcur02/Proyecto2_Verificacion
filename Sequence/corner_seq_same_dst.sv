`include "uvm_macros.svh"
import uvm_pkg::*;

// Secuencia que genera 50 transacciones con el mismo destino (0,1) y gap 0
class corner_seq_same_dst extends uvm_sequence #(trans_item);
  `uvm_object_utils(corner_seq_same_dst)

  function new(string name = "corner_seq_same_dst");
    super.new(name);
  endfunction

  virtual task body();
    for (int k = 0; k < 50; k++) begin
      trans_item it = trans_item::type_id::create($sformatf("corner_it_%0d", k));
      start_item(it);
      assert(it.randomize() with {
        target_row_out    == 0;
        target_column_out == 1;
        send_gap          == 0;
      });
      finish_item(it);
    end
  endtask
endclass