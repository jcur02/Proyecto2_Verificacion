`include "uvm_macros.svh"
`include "Archivos_proyecto_2/Router_library.sv"
import uvm_pkg::*;

// This is the base transaction object that will be used
// in the environment to initiate new transactions and 
// capture transactions at DUT interface
class trans_item extends uvm_sequence_item;
  localparam int PCK_SZ = 40;

  rand bit [3:0] target_row_out;
  rand bit [3:0] target_column_out;
  rand bit mode;
  rand bit [PCK_SZ-18:0] payload;
  bit [7:0] next_jump;
  bit [PCK_SZ-1:0] packet;
  randc bit [3:0] sender;
  bit [3:0] receptor;
  rand bit [5:0] send_gap;  // en ciclos
  rand bit          inject_error;
  
  static time send_t_send[6][6][$];
  static int  send_src    [6][6][$];

  // constraints 
  constraint trgt1 { target_row_out inside {0,1,2,3,4,5}; }
  constraint trgt2 { target_column_out inside {0,1,2,3,4,5}; }
  constraint trgt3 { (target_column_out==0 || target_column_out==5) -> target_row_out inside {1,2,3,4}; }
  constraint trgt4 { (target_row_out==0 || target_row_out==5) -> target_column_out inside {1,2,3,4}; }
  constraint source { sender >= 0; sender <= 15; }
  constraint mod    { mode inside {0,1}; }
  constraint pld    { payload >= 0; payload <= 256; }
  constraint gap_c { send_gap inside {[0:20]}; }
  constraint err_c { inject_error dist {0 := 8, 1 := 2}; } // ~20% con error
  
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
    `uvm_field_int (send_gap, UVM_DEFAULT)
    `uvm_field_int (inject_error, UVM_DEFAULT)
  `uvm_object_utils_end
  
  // constructor
  function new(string name = "trans_item");
    super.new(name);
    next_jump = '0;
  endfunction
  
endclass

// The generator class is replaced by a sequence
// Sequence that implements the behavior of the original generator class
class gen_sequence extends uvm_sequence;
  `uvm_object_utils(gen_sequence)
  function new(string name = "gen_sequence");
    super.new(name);
  endfunction

  rand int num_per_terminal[16];

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

class all_src_same_dst_seq extends uvm_sequence #(trans_item);
  `uvm_object_utils(all_src_same_dst_seq)

  function new(string name = "all_src_same_dst_seq");
    super.new(name);
  endfunction
  
  virtual task body();
    for (int s = 0; s < 16; s++) begin
      for (int k = 0; k < 5; k++) begin
        trans_item it = trans_item::type_id::create($sformatf("it_%0d_%0d", s, k));
        start_item(it);
        assert(it.randomize() with {
          sender           == s;
          target_row_out    == 0;
          target_column_out == 1;
          send_gap          == 0;
        });
        `uvm_info("SEQ", $sformatf("Generate item from terminal %0d with gap of %0d", s, it.send_gap), UVM_LOW)
        finish_item(it);
      end
    end
  endtask
endclass

// The driver is responsible for driving transactions to the DUT 
// All it does is to get a transaction from the mailbox if it is 
// available and drive it out into the DUT interface.
class trans_driver extends uvm_driver#(trans_item);
  `uvm_component_utils(trans_driver)
  
  localparam int PCK_SZ = 40;
  
  function new(string name = "trans_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // virtual interface 
  virtual mesh_gnrt_if vif;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual mesh_gnrt_if)::get(this, "", "vif", vif)) 
      `uvm_fatal("DRV", "Could not get vif")
  endfunction

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      trans_item m_item;
      // request next sequence item
      `uvm_info("DRV", $sformatf("Wait for item from sequencer"), UVM_LOW)
      seq_item_port.get_next_item(m_item);
      drive_item(m_item);
      // notify sequence that item is done
      seq_item_port.item_done();
    end
  endtask
    
  virtual task drive_item(trans_item m_item);

    // Esperar un número aleatorio de ciclos antes de inyectar el paquete
    repeat (m_item.send_gap) @(posedge vif.clk);

    m_item.packet = { m_item.next_jump,
                      m_item.target_row_out,
                      m_item.target_column_out,
                      m_item.mode,
                      m_item.payload };

    // Inyectar error si corresponde (ver punto 3)
    if (m_item.inject_error) begin
      m_item.packet[0] = ~m_item.packet[0]; // flip de 1 bit, por ejemplo
    end

    vif.pndng_i_in[m_item.sender]    <= 1'b1;
    vif.data_out_i_in[m_item.sender] <= m_item.packet;

    // registrar envío 
    trans_item::send_t_send[m_item.target_row_out]
                           [m_item.target_column_out].push_back($time);
    trans_item::send_src[m_item.target_row_out]
                        [m_item.target_column_out].push_back(m_item.sender);

    // handshake
    wait (vif.popin[m_item.sender] == 1'b1);
    @(posedge vif.clk);
    vif.pndng_i_in[m_item.sender]    <= 1'b0;
    vif.data_out_i_in[m_item.sender] <= '0;
    @(posedge vif.clk);
  endtask


endclass
    
// The monitor has a virtual interface handle with which 
// it can monitor the events happening on the interface.
// It sees new transactions and then captures information 
// into a packet and sends it to the scoreboard
// using another mailbox.
// Monitor that observes the mesh_gnrt interface and publishes trans_item
class trans_monitor extends uvm_monitor;
  `uvm_component_utils(trans_monitor)

  localparam int PCK_SZ = 40;

  function new(string name = "trans_monitor", uvm_component parent = null);
    super.new(name, parent);
    cg = new();
  endfunction

  uvm_analysis_port#(trans_item) ap;
  virtual mesh_gnrt_if vif;

  bit seen[16];
  time last_recv_time[16];
  integer csv_fd;
  // Variables para cobertura
  int cov_src_terminal;
  int cov_receptor;
  int cov_row, cov_col;
  bit cov_mode;
  int unsigned cov_delay;
  
  // --------- Cobertura funcional --------------
  covergroup cg;
    // terminal fuente y destino
    cp_src : coverpoint cov_src_terminal {
      bins all_terms[] = {[0:15]};
    }
    cp_dst : coverpoint cov_receptor {
      bins all_terms[] = {[0:15]};
    }

    // fila y columna de destino
    cp_row : coverpoint cov_row {
      bins rows[] = {[0:5]};
    }

    cp_col : coverpoint cov_col {
      bins cols[] = {[0:5]};
    }

    // modo de operación
    cp_mode : coverpoint cov_mode {
      bins modo0 = {0};
      bins modo1 = {1};
    }

    // retardo 
    cp_delay : coverpoint cov_delay {
      bins corto  = {[0:10]};
      bins medio  = {[11:50]};
      bins largo  = {[51:$]};
    }

    // crosses interesantes
    cr_dst_row_col : cross cp_dst, cp_row, cp_col;
    cr_src_dst     : cross cp_src, cp_dst;
  endgroup : cg


  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual mesh_gnrt_if)::get(this, "", "vif", vif))
      `uvm_fatal("MON", "Could not get vif")
    ap = new("mon_analysis_port", this);

    foreach (seen[i]) seen[i] = 1'b0;
    
    // Abrir CSV y escribir encabezado
    csv_fd = $fopen("reporte_paquetes.csv", "w");
    if (csv_fd == 0)
      `uvm_fatal("MON", "No se pudo abrir reporte_paquetes.csv")

    // Encabezado
      $fwrite(csv_fd, "t_envio,terminal_src,terminal_dst,row_dst,col_dst,t_recibo,retardo,delta_t,bw_bits_per_cycle\n");
  endfunction

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    sample_port("MON");
  endtask

  virtual task sample_port(string tag="");
    int  i;
    int  row, col, src_terminal;
    time t_recv, t_send, delay;
    time delta_t, bw_bits;
    forever begin
      @(posedge vif.clk);
      for (i = 0; i < 16; i++) begin
        if (vif.pndng[i] && !seen[i]) begin
          trans_item item = new;

          item.packet   = vif.data_out[i];
          item.receptor = i;

          { item.next_jump,
            item.target_row_out,
            item.target_column_out,
            item.mode,
            item.payload } = vif.data_out[i];
          
          // ---- Recuperar info de envío para este destino ----
          row    = item.target_row_out;
          col    = item.target_column_out;
          t_recv = $time;

          if (trans_item::send_t_send[row][col].size() > 0) begin
            t_send       = trans_item::send_t_send[row][col].pop_front();
            src_terminal = trans_item::send_src[row][col].pop_front();
            delay        = t_recv - t_send;
          end
          else begin
            // Por si algo raro pasa, que no reviente
            t_send       = 0;
            src_terminal = -1;
            delay        = 0;
          end

          // ---- Calcular delta_t y ancho de banda ----
          if (last_recv_time[item.receptor] == 0) begin
            delta_t = 0;
            bw_bits = 0;
          end
          else begin
            delta_t = t_recv - last_recv_time[item.receptor];
            if (delta_t == 0)
              bw_bits = 0;
            else
              bw_bits = PCK_SZ / delta_t; // 40 bits / ciclos 
          end
          last_recv_time[item.receptor] = t_recv;

          // ---- Escribir al CSV ----
          // t_envio,terminal_src,terminal_dst,row_dst,col_dst,t_recibo,retardo,delta_t,bw_bits_per_cycle
          $fwrite(csv_fd, "%0t,%0d,%0d,%0d,%0d,%0t,%0t,%0t,%0t\n",
                  t_send, src_terminal, item.receptor,
                  row, col, t_recv, delay, delta_t, bw_bits);
		  // ---- Cobertura: cargar variables y samplear ----
          cov_src_terminal = src_terminal;
          cov_receptor     = item.receptor;
          cov_row          = row;
          cov_col          = col;
          cov_mode         = item.mode;
          cov_delay        = delay;   

          cg.sample();
          ap.write(item);
          `uvm_info("MON", $sformatf("T=%0t [Monitor] %s over, item:", 
                                     $time, tag), UVM_LOW)
          item.print();

          vif.pop[i] <= 1'b1;
          seen[i]    = 1'b1;   // marcamos que ya lo contamos
        end
        else if (!vif.pndng[i]) begin
          vif.pop[i] <= 1'b0;
          seen[i]    = 1'b0;
        end
        // si vif.pndng[i] == 1 y seen[i] == 1: no hacemos nada
      end
    end
  endtask
  
  virtual function void final_phase(uvm_phase phase);
    super.final_phase(phase);
    if (csv_fd)
      $fclose(csv_fd);
  endfunction
endclass
                    
// The scoreboard is responsible to check data integrity. Since
// the design routes packets based on an address range, the
// scoreboard checks that the packet's address is within valid
// range.
class trans_scoreboard extends uvm_component;
  `uvm_component_utils(trans_scoreboard)

  function new(string name = "trans_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  uvm_analysis_imp#(trans_item, trans_scoreboard) mon_imp;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon_imp = new("m_analysis_imp", this);
  endfunction

  virtual function void write(trans_item t);
    if (t.receptor == 0) begin
      if (t.target_row_out != 0 | t.target_column_out != 1)
        `uvm_error("SCBD", $sformatf("ERROR! Mismatch receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out))
      else
        `uvm_info("SCBD", $sformatf("PASS! Match receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out), UVM_LOW)
    end
    else if (t.receptor == 1) begin
      if (t.target_row_out != 0 | t.target_column_out != 2)
        `uvm_error("SCBD", $sformatf("ERROR! Mismatch receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out))
      else
        `uvm_info("SCBD", $sformatf("PASS! Match receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out), UVM_LOW)
	end
    else if (t.receptor == 2) begin
      if (t.target_row_out != 0 | t.target_column_out != 3)
        `uvm_error("SCBD", $sformatf("ERROR! Mismatch receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out))
      else
        `uvm_info("SCBD", $sformatf("PASS! Match receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out), UVM_LOW)
	end
    else if (t.receptor == 3) begin
      if (t.target_row_out != 0 | t.target_column_out != 4)
        `uvm_error("SCBD", $sformatf("ERROR! Mismatch receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out))
      else
        `uvm_info("SCBD", $sformatf("PASS! Match receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out), UVM_LOW)
	end
    else if (t.receptor == 4) begin
      if (t.target_row_out != 1 | t.target_column_out != 0)
        `uvm_error("SCBD", $sformatf("ERROR! Mismatch receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out))
      else
        `uvm_info("SCBD", $sformatf("PASS! Match receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out), UVM_LOW)
	end
    else if (t.receptor == 5) begin
      if (t.target_row_out != 2 | t.target_column_out != 0)
        `uvm_error("SCBD", $sformatf("ERROR! Mismatch receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out))
      else
        `uvm_info("SCBD", $sformatf("PASS! Match receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out), UVM_LOW)
	end
    else if (t.receptor == 6) begin
      if (t.target_row_out != 3 | t.target_column_out != 0)
        `uvm_error("SCBD", $sformatf("ERROR! Mismatch receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out))
      else
        `uvm_info("SCBD", $sformatf("PASS! Match receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out), UVM_LOW)
	end
    else if (t.receptor == 7) begin
      if (t.target_row_out != 4 | t.target_column_out != 0)
        `uvm_error("SCBD", $sformatf("ERROR! Mismatch receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out))
      else
        `uvm_info("SCBD", $sformatf("PASS! Match receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out), UVM_LOW)
	end
    else if (t.receptor == 8) begin
      if (t.target_row_out != 5 | t.target_column_out != 1)
        `uvm_error("SCBD", $sformatf("ERROR! Mismatch receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out))
      else
        `uvm_info("SCBD", $sformatf("PASS! Match receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out), UVM_LOW)
	end
    else if (t.receptor == 9) begin
      if (t.target_row_out != 5 | t.target_column_out != 2)
        `uvm_error("SCBD", $sformatf("ERROR! Mismatch receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out))
      else
        `uvm_info("SCBD", $sformatf("PASS! Match receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out), UVM_LOW)
	end
    else if (t.receptor == 10) begin
      if (t.target_row_out != 5 | t.target_column_out != 3)
        `uvm_error("SCBD", $sformatf("ERROR! Mismatch receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out))
      else
        `uvm_info("SCBD", $sformatf("PASS! Match receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out), UVM_LOW)
	end
    else if (t.receptor == 11) begin
      if (t.target_row_out != 5 | t.target_column_out != 4)
        `uvm_error("SCBD", $sformatf("ERROR! Mismatch receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out))
      else
        `uvm_info("SCBD", $sformatf("PASS! Match receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out), UVM_LOW)
	end
    else if (t.receptor == 12) begin
      if (t.target_row_out != 1 | t.target_column_out != 5)
        `uvm_error("SCBD", $sformatf("ERROR! Mismatch receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out))
      else
        `uvm_info("SCBD", $sformatf("PASS! Match receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out), UVM_LOW)
	end
    else if (t.receptor == 13) begin
      if (t.target_row_out != 2 | t.target_column_out != 5)
        `uvm_error("SCBD", $sformatf("ERROR! Mismatch receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out))
      else
        `uvm_info("SCBD", $sformatf("PASS! Match receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out), UVM_LOW)
	end
    else if (t.receptor == 14) begin
      if (t.target_row_out != 3 | t.target_column_out != 5)
        `uvm_error("SCBD", $sformatf("ERROR! Mismatch receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out))
      else
        `uvm_info("SCBD", $sformatf("PASS! Match receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out), UVM_LOW)
	end
    else if (t.receptor == 15) begin
      if (t.target_row_out != 4 | t.target_column_out != 5)
        `uvm_error("SCBD", $sformatf("ERROR! Mismatch receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out))
      else
        `uvm_info("SCBD", $sformatf("PASS! Match receptor=0x%0h row=0x%0h column=0x%0h", t.receptor, t.target_row_out, t.target_column_out), UVM_LOW)
	end
        
  endfunction 
endclass
        
// Create an intermediate container called "agent" to hold
// driver, monitor and sequencer          
class trans_agent extends uvm_agent;
  `uvm_component_utils(trans_agent)
  function new(string name = "trans_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // child components (public so env can access their ports)
  uvm_sequencer #(trans_item)	sequencer;
  trans_driver    driver;
  trans_monitor   monitor;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // create child components using factory
    sequencer = uvm_sequencer#(trans_item)::type_id::create("sequencer", this);
    driver    = trans_driver::type_id::create("driver", this);
    monitor   = trans_monitor::type_id::create("monitor", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // connect sequencer to driver
    driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction

endclass
      
// The environment is a container object simply to hold 
// all verification  components together. This environment can
// then be reused later and all components in it would be
// automatically connected and available for use
class trans_env extends uvm_env;
  `uvm_component_utils(trans_env)
  function new(string name = "trans_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  trans_agent agent;
  trans_scoreboard scoreboard;
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // create scoreboard
    scoreboard = trans_scoreboard::type_id::create("scoreboard", this);
    agent = trans_agent::type_id::create("agent", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.monitor.ap.connect(scoreboard.mon_imp);
  endfunction

endclass
      
// Test class instantiates the environment and starts it.
class trans_test extends uvm_test;
  `uvm_component_utils(trans_test)
  function new(string name = "trans_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  trans_env env;
  virtual mesh_gnrt_if vif;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = trans_env::type_id::create("trans_env", this);
    if (!uvm_config_db#(virtual mesh_gnrt_if)::get(this, "", "vif", vif))
      `uvm_fatal("TEST", "Did not get vif")
      
      uvm_config_db#(virtual mesh_gnrt_if)::set(this, "trans_env.agent.*", "vif", vif);
  endfunction

  virtual task run_phase(uvm_phase phase);
    gen_sequence         seq_random;
    corner_seq_same_dst  seq_corner;
    all_src_same_dst_seq  seq_corner2;

    phase.raise_objection(this);
    apply_reset();

    // 1) Tráfico random
    seq_random = gen_sequence::type_id::create("seq_random");
    assert(seq_random.randomize());
    seq_random.start(env.agent.sequencer);

    // 2) Caso de esquina
    seq_corner = corner_seq_same_dst::type_id::create("seq_corner");
    seq_corner.start(env.agent.sequencer);

    // 3) Caso de esquina
    seq_corner2 = all_src_same_dst_seq::type_id::create("seq_corner2");
    seq_corner2.start(env.agent.sequencer);

    repeat (5000) @(posedge vif.clk);
    phase.drop_objection(this);
  endtask

  
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

    // Reset inicial normal
    apply_reset();

    // 1) Arrancás tráfico random
    seq = gen_sequence::type_id::create("seq");
    assert(seq.randomize());
    fork
      seq.start(env.agent.sequencer); 
    join_none

    // 2) Dejá que se llene un poco la red
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

      
interface mesh_gnrt_if(input bit clk);
  logic reset;
  logic pndng[16];
  logic [39:0] data_out[16];
  logic popin[16];
  logic pop[16];
  logic [39:0] data_out_i_in[16];
  logic pndng_i_in[16];

  // =================================================
  // Aserciones
  // =================================================
  genvar gi;
  generate
    for (gi = 0; gi < 16; gi++) begin : ASSERTS

      // 1) No sacar pop si no hay pendiente
      property pop_only_if_pndng;
        @(posedge clk) disable iff (reset)
          pop[gi] |-> (pndng[gi] or $past(pndng[gi]));
      endproperty
      assert_pop_only_if_pndng: assert property (pop_only_if_pndng)
        else $error("POP sin PNDNG en terminal %0d", gi);

      // 2) Si hay pndng, eventualmente debe haber pop
      property pndng_eventually_pop;
        @(posedge clk) disable iff (reset)
        $rose(pndng[gi]) |-> ##[1:100] pop[gi];
      endproperty
      assert_pndng_eventually_pop: assert property (pndng_eventually_pop)
        else $error("PNDNG en %0d no atendido en 20 ciclos", gi);

      // 3) Para el lado de entrada: pndng_i_in debe generar popin pronto
      property in_pndng_eventually_popin;
        @(posedge clk) disable iff (reset)
        $rose(pndng_i_in[gi]) |-> ##[1:100] popin[gi];
      endproperty
      assert_in_pndng_eventually_popin: assert property (in_pndng_eventually_popin)
        else $error("PNDNG_I_IN en %0d no genera POPIN en 20 ciclos", gi);

    end
  endgenerate
endinterface

// Top level testbench module to instantiate design, interface
// start clocks and run the test
module tb;
  reg clk;
  
  always #10 clk =~ clk;
  mesh_gnrt_if 	_if (clk);
  mesh_gnrtr u0 ( 	.clk(clk),
             .pndng(_if.pndng),
             .data_out(_if.data_out),
             .popin (_if.popin),
             .pop(_if.pop),
             .data_out_i_in(_if.data_out_i_in),
             .pndng_i_in(_if.pndng_i_in),
             .reset(_if.reset));
  trans_test t0;
  
  initial begin
    clk <= 0;
    uvm_config_db#(virtual mesh_gnrt_if)::set(null, "uvm_test_top", "vif", _if);
    run_test("trans_test");
    //run_test("trans_test_reset_mid_traffic");
  end
  
  // System tasks to dump VCD waveform file
  initial begin
    $dumpfile("dump.vcd"); 
    $dumpvars(0, tb);
  end
endmodule