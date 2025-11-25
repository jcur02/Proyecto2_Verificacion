`include "uvm_macros.svh"
import uvm_pkg::*;

class trans_driver extends uvm_driver#(trans_item);
  `uvm_component_utils(trans_driver)
  
  localparam int PCK_SZ = 40;
  
    // constructor
  function new(string name = "trans_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // virtual interface
  virtual mesh_gnrt_if vif;

  // build phase
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual mesh_gnrt_if)::get(this, "", "vif", vif)) 
      `uvm_fatal("DRV", "Could not get vif")
  endfunction

  // run phase
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      trans_item m_item;
      // esperar siguiente item de la secuencia
      `uvm_info("DRV", $sformatf("Wait for item from sequencer"), UVM_LOW)
      seq_item_port.get_next_item(m_item);
      // enviar item al DUT
      drive_item(m_item);
      // notificar a la secuencia que el item ha sido enviado
      seq_item_port.item_done();
    end
  endtask
    
    // task para enviar la transaccion al DUT
  virtual task drive_item(trans_item m_item);

    // Esperar retraso de ciclos antes de enviar el paquete
    repeat (m_item.send_gap) @(posedge vif.clk);
    // generar el paquete completo a enviar al DUT
    m_item.packet = { m_item.next_jump,
                  m_item.target_row_out,
                  m_item.target_column_out,
                  m_item.mode,
                  m_item.payload };

    // Inyectar error 
    if (m_item.inject_error) begin
      m_item.packet[0] = ~m_item.packet[0]; 
    end
    
    // poner pnding en 1 y cargar datos
    vif.pndng_i_in[m_item.sender] <= 1'b1;
    vif.data_out_i_in[m_item.sender] <= m_item.packet;

    // registrar envío 
    trans_item::send_t_send[m_item.target_row_out]
                           [m_item.target_column_out].push_back($time);
    trans_item::send_src[m_item.target_row_out]
                        [m_item.target_column_out].push_back(m_item.sender);
      
    // esperar a que el DUT lea los datos
    wait (vif.popin[m_item.sender] == 1'b1);
    @ (posedge vif.clk);

    // limpiar pnding y datos
    vif.pndng_i_in[m_item.sender] <= 1'b0;
    vif.data_out_i_in[m_item.sender] <= 0;
    @(posedge vif.clk);
    
  endtask

endclass