`include "uvm_macros.svh"
package scoreboard; 
    import uvm_pkg::*;
    import sequences::*;

    class alu_scoreboard extends uvm_scoreboard;
        `uvm_component_utils(alu_scoreboard)

        uvm_analysis_export #(alu_transaction_in) sb_in;
        uvm_analysis_export #(alu_transaction_out) sb_out;

        uvm_tlm_analysis_fifo #(alu_transaction_in) fifo_in;
        uvm_tlm_analysis_fifo #(alu_transaction_out) fifo_out;

        alu_transaction_in tx_in;
        alu_transaction_out tx_out;

        function new(string name, uvm_component parent);
            super.new(name,parent);
            tx_in=new("tx_in");
            tx_out=new("tx_out");
        endfunction: new

        function void build_phase(uvm_phase phase);
            sb_in=new("sb_in",this);
            sb_out=new("sb_out",this);
            fifo_in=new("fifo_in",this);
            fifo_out=new("fifo_out",this);
        endfunction: build_phase

        function void connect_phase(uvm_phase phase);
            sb_in.connect(fifo_in.analysis_export);
            sb_out.connect(fifo_out.analysis_export);
        endfunction: connect_phase
 
        task run();
            forever begin
                fifo_in.get(tx_in);
                fifo_out.get(tx_out);
                compare();
            end
        endtask: run

        extern virtual function [33:0] getresult; 
        extern virtual function void compare; 
            
    endclass: alu_scoreboard

    function void alu_scoreboard::compare;
        //TODO: Write this function to check whether the output of the DUT matches
        //the spec.
        //Use the getresult() function to get the spec output.
        //Consider using `uvm_info(ID,MSG,VERBOSITY) in this function to print the
        //results of the comparison.
        //You can use tx_in.convert2string() and tx_out.convert2string() for
        //debugging purposes
        logic [33:0] result, actual_result;
        logic[32:0] local_result;
        logic local_vout;
        int B;
        result = getresult();

        `uvm_info("TX_IN",tx_in.convert2string,UVM_HIGH);
        `uvm_info("TX_OUT",tx_out.convert2string,UVM_HIGH);

        case (tx_in.opcode)
            5'b00111:   actual_result = {1'b0,1'b0,(tx_in.A | tx_in.B)};//logical OR
            5'b00011:   actual_result = {1'b0, 1'b0,(tx_in.A ^ tx_in.B)}; //logical XOR
            5'b00000:   actual_result = {1'b0,1'b0,(~tx_in.A)};//logical NOT
            5'b00101:   actual_result = {1'b0,1'b0,(tx_in.A & tx_in.B)};//logical AND

            5'b01100: actual_result = {1'b0,1'b0,((int'(tx_in.A) <= int'(tx_in.B))?32'h0000_0001:32'h0)};//sle
            5'b01001: actual_result = {1'b0,1'b0,((int'(tx_in.A) < int'(tx_in.B))?32'h0000_0001:32'h0)};//slt
            5'b01110: actual_result = {1'b0,1'b0,((int'(tx_in.A) >= int'(tx_in.B))?32'h0000_0001:32'h0)}; //sge
            5'b01011: actual_result = {1'b0,1'b0,((int'(tx_in.A) > int'(tx_in.B))?32'h0000_0001:32'h0)};//sgt
            5'b01111: actual_result = {1'b0,1'b0,((int'(tx_in.A) == int'(tx_in.B))?32'h0000_0001:32'h0)};//seq
            5'b01010: actual_result = {1'b0,1'b0,((int'(tx_in.A) != int'(tx_in.B))?32'h0000_0001:32'h0)};//sne


            5'b10101: //add
                begin
                    local_result = tx_in.A + tx_in.B + tx_in.CIN;
                    case({tx_in.A[31],tx_in.B[31]})
                        2'b00:  local_vout = ((local_result[31])  ? 1'b1: 1'b0);  //overflow when sign change
                        2'b01:  local_vout = 1'b0;//no overflow 
                        2'b10:  local_vout = 1'b0;//no overflow
                        2'b11:  local_vout = ((!local_result[31]) ? 1'b1 : 1'b0); //overflow when sign change
                    endcase
                    actual_result =  {local_vout,local_result[32],local_result[31:0]};
                end
            5'b10001:  //addu
                begin
                    //carry out is the overflow
                    local_result = tx_in.A + tx_in.B + tx_in.CIN;
                    actual_result = {local_result[32], local_result[32],local_result[31:0]};
                end
            5'b10100:   //sub
                begin
                    int A = tx_in.A;
                    int B = tx_in.B;
                    local_result = tx_in.A - tx_in.B; 
                    case({tx_in.A[31],tx_in.B[31]})
                        2'b00:  local_vout = 1'b0;  //no sign change
                        2'b01:  local_vout = local_result[31];  //MSB is the overflow
                        2'b10:  local_vout = !local_result[31];
                        2'b11:  local_vout = 1'b0;
                    endcase
                    actual_result = {local_vout, local_result[32],local_result[31:0]};
                end
            5'b10000:    //subu
                begin
                    logic[32:0]  operand_B;
                    B = ~tx_in.B;
                    operand_B = ~tx_in.B + 1'b1;
                    local_result = tx_in.A + operand_B;
                    actual_result = {1'b0,local_result[32],local_result[31:0]}; 
                end
            5'b10111:   //inc
                begin
                    local_result = tx_in.A + 1;
                    case({tx_in.A[31],1'b0})
                        2'b00:  local_vout = (local_result[31])  ?  1'b1: 1'b0;  //overflow when sign change
                        2'b10:  local_vout = 1'b0;//no overflow
                    endcase
                    actual_result =  {local_vout,local_result[32],local_result[31:0]};
                end
            5'b10110:   //dec
                begin
                    int A = tx_in.A;
                    local_result = tx_in.A - 1; 
                    case({tx_in.A[31],1'b0})
                        2'b00:  local_vout = 1'b0;  //no sign change
                        2'b10:  local_vout = !local_result[31];
                    endcase
                    actual_result = {local_vout,local_result[32],local_result[31:0]};
                end
            5'b11010:    //sll
                begin
                   local_result = tx_in.A << tx_in.B[4:0]; 
                   actual_result = {tx_out.VOUT,1'b0,local_result[31:0]};
                end
            5'b11011:     //srl
                begin
                   local_result = tx_in.A >> tx_in.B[4:0]; 
                   actual_result = {tx_out.VOUT,1'b0,local_result[31:0]};
                end
            5'b11100:      //sla
                begin
                    local_result = tx_in.A <<< tx_in.B[4:0];
                    local_vout = (tx_in.A[31] ^ tx_in.A[30]) | (tx_in.A[31] ^ local_result[31]);
                    actual_result = {local_vout, 1'b0,local_result[31:0]};
                end
            5'b11101:  //sra
                begin
                    logic[31:0] local_res;
                    local_res = tx_in.A[31:0] >>> tx_in.B[4:0];
                    // shift_msb = tx_in.A[tx_in.B[4:0] - 1];
                    local_vout = tx_in.A[31] ^ local_res[31];
                    actual_result = {local_vout, 1'b0,local_res[31:0]};
                end
            5'b11000:     //slr
                begin
                    logic[31:0] local_res;
                    local_res = (tx_in.A << tx_in.B[4:0]) | (tx_in.A >> 32-tx_in.B[4:0]);
                    actual_result = {tx_out.VOUT,1'b0,local_res};
                end
            5'b11001:     //srr
                begin
                    logic[31:0] local_res;
                    local_res = (tx_in.A >> tx_in.B[4:0]) | (tx_in.A << 32-tx_in.B[4:0]);
                    actual_result = {tx_out.VOUT,1'b0,local_res};
                end
            default: 
                actual_result = 34'b0;
        endcase

        if(actual_result == result) begin
            `uvm_info("PASS INFO",{$sformatf(" Passed...realOUT = %b, realCOUT = %b, realVOUT = %b\n\n",actual_result[31:0],actual_result[32],actual_result[33])},UVM_HIGH);
        end
        else begin
            `uvm_info("FAIL INFO",{$sformatf(" Failed...realOUT = %b, realCOUT = %b, realVOUT = %b\n\n",actual_result[31:0],actual_result[32],actual_result[33])},UVM_HIGH);
        end

    endfunction

    function [33:0] alu_scoreboard::getresult;
        //TODO: Remove the statement below
        //Modify this function to return a 34-bit result {VOUT, COUT,OUT[31:0]} which is
        //consistent with the given spec.
        logic [33:0] result;
        result = {tx_out.VOUT, tx_out.COUT,tx_out.OUT[31:0]};
        return result;
    endfunction

endpackage: scoreboard
