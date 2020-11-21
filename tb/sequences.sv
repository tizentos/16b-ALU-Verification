`include "uvm_macros.svh"
package sequences;

    import uvm_pkg::*;

    class alu_transaction_in extends uvm_sequence_item;
        `uvm_object_utils(alu_transaction_in)
         // TODO: Register the  alu_transaction_in object. Hint: Look at other classes to find out what is missing.

        rand logic [31:0] A;
        rand logic [31:0] B;
        rand logic [4:0] opcode;
        rand logic rst;
        rand logic CIN;

        constraint opcode_distrib{
            opcode dist {
                // 5'b10100 := 0,
                // 5'b10001 := 0,
                // 5'b01100 := 0,  //sle
                // 5'b01001 :=0,  //slt
                // 5'b01110 := 0,  //sge
                // 5'b01011 := 0,  //sgt
                // 5'b01111 := 0,   //seq
                // 5'b01010 := 0,   //sne
                // 5'b11100 := 0,  //sla
                [5'b00000:5'b11111] :=100
                // 5'b11000 := 0
            };
        }
        //TODO: Add constraints here
        constraint carry_in_constraint {
            if(opcode == 5'b10100 || (opcode == 5'b10000)) { CIN == 1'b1;}
            else if (opcode == 5'b10101 || (opcode == 5'b10001)){ CIN inside{[0:1]};}
        }

        // constraint corner_case_constraint {
        //     A == 32'hFFFF_FFFF;
        // }

        
        constraint reset_signal {
            rst == 1'b0;
        }
        


        function new(string name = "");
            super.new(name);
        endfunction: new

        function string convert2string;
            convert2string={$sformatf("Operand A = 0x%h, Operand B = 0x%h, Opcode = %b, CIN = %b, RST = %b",A,B,opcode,CIN,rst)};
        endfunction: convert2string

    endclass: alu_transaction_in


    class alu_transaction_out extends uvm_sequence_item;
        `uvm_object_utils(alu_transaction_out)
        // TODO: Register the  alu_transaction_out object. Hint: Look at other classes to find out what is missing.

        logic [31:0] OUT;
        logic COUT;
        logic VOUT;

        function new(string name = "");
            super.new(name);
        endfunction: new;
        
        function string convert2string;
            convert2string={$sformatf("OUT = %b, COUT = %b, VOUT = %b",OUT,COUT,VOUT)};
        endfunction: convert2string

    endclass: alu_transaction_out

    class simple_seq extends uvm_sequence #(alu_transaction_in);
        `uvm_object_utils(simple_seq)

        function new(string name = "");
            super.new(name);
        endfunction: new

        task body;
            alu_transaction_in tx;
            tx=alu_transaction_in::type_id::create("tx");
            start_item(tx);
            assert(tx.randomize());
            finish_item(tx);
        endtask: body
    endclass: simple_seq


    class seq_of_commands extends uvm_sequence #(alu_transaction_in);
        `uvm_object_utils(seq_of_commands)
        `uvm_declare_p_sequencer(uvm_sequencer#(alu_transaction_in))

        function new (string name = "");
            super.new(name);
        endfunction: new

        task body;
            repeat(100)
            begin
                simple_seq seq;
                seq = simple_seq::type_id::create("seq");
                assert( seq.randomize() );
                seq.start(p_sequencer);
            end
        endtask: body

    endclass: seq_of_commands

endpackage: sequences