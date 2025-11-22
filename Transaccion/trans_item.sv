`include "uvm_macros.svh"
import uvm_pkg::*;

class trans_item extends uvm_sequence_item;
  localparam int PCK_SZ = 40;

  rand bit [3:0] target_row_out;
  rand bit [3:0] target_column_out;
  rand bit mode; // 0: column first, 1: row first
  rand bit [PCK_SZ-18:0] payload;
  bit [7:0] next_jump;
  bit [PCK_SZ-1:0] packet; // paquete completo para enviar al DUT
  randc bit [3:0] sender; // ID del nodo que envia la transaccion
  bit [3:0] receptor; // ID del nodo que recibe la transaccion

  // constraints 
  constraint trgt1 { target_row_out inside {0,1,2,3,4,5}; }
  constraint trgt2 { target_column_out inside {0,1,2,3,4,5}; }
  constraint trgt3 { (target_column_out==0 || target_column_out==5) -> target_row_out inside {1,2,3,4}; }
  constraint trgt4 { (target_row_out==0 || target_row_out==5) -> target_column_out inside {1,2,3,4}; }
  constraint source { sender >= 0; sender <= 15; }
  constraint mod    { mode inside {0,1}; }
  constraint pld    { payload >= 0; payload <= 256; }
  
  constraint border_only {
    (target_row_out == 0 && target_column_out inside {[1:4]}) || // borde superior
    (target_row_out == 5 && target_column_out inside {[1:4]}) || // borde inferior
    (target_column_out == 0 && target_row_out inside {[1:4]}) || // borde izquierdo
    (target_column_out == 5 && target_row_out inside {[1:4]});   // borde derecho
  }

  `uvm_object_utils_begin(trans_item)
  	`uvm_field_int (target_row_out, UVM_DEFAULT)
  	`uvm_field_int (target_column_out, UVM_DEFAULT)
  	`uvm_field_int (mode, UVM_DEFAULT)
  	`uvm_field_int (payload, UVM_DEFAULT)
  	`uvm_field_int (next_jump, UVM_DEFAULT)
  	`uvm_field_int (packet, UVM_DEFAULT)
    `uvm_field_int (sender, UVM_DEFAULT)
  	`uvm_field_int (receptor, UVM_DEFAULT)
  `uvm_object_utils_end
  
  // constructor
  function new(string name = "trans_item");
    super.new(name);
    next_jump = '0;
  endfunction
  
endclass