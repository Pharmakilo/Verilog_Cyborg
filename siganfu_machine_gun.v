`timescale 1ms / 100ns

module siganfu_machine_gun (
	input sysclk,
	input reboot,
	input target_locked,
	input is_enemy,
	input fire_command,
	input firing_mode, // 0 single, 1 auto
	input overheat_sensor,
	output reg[2:0] current_state,
	output reg criticality_alert,
	output reg fire_trigger
);
    //single_previous is used for not shooting more than one bullet for the state shoot_single
	reg [2:0] nextstate;  
    integer single_previous, current_bullet, spare_magazine, i;
    parameter idle=3'b000, shoot_single=3'b001, shoot_auto=3'b010, reload=3'b011, overheat=3'b100, downfall=3'b101;
    
initial begin
criticality_alert=0; fire_trigger=0; single_previous=0; current_bullet=25; spare_magazine=3; end

always @(posedge sysclk or posedge reboot ) // always block to update state 
if(reboot==1) begin 
    current_state <= idle;  
    if (sysclk==1) begin
    current_state <= nextstate;
    end end
else 
    current_state <= nextstate; 
always @(current_state or target_locked or is_enemy or fire_command or firing_mode or overheat_sensor) // always block to compute both output & nextstate 
begin    
    case(current_state) 
        idle: if(is_enemy==1 & target_locked==1 & fire_command==1 & firing_mode==0) begin             
                    nextstate = shoot_single; end 
                else if(is_enemy==1 & target_locked==1 & fire_command==1 & firing_mode==1) begin
                    nextstate = shoot_auto; end
                else begin
                    nextstate = idle; end
        shoot_auto: if(overheat_sensor==1) begin
                        nextstate = overheat;  end
                    else begin
                        if(current_bullet==0 & spare_magazine==0) begin
                            nextstate = downfall; end
                        else if(current_bullet==0 & spare_magazine!=0) begin
                            nextstate = reload; end
                        else begin
                            if(is_enemy==0 | target_locked==0 | fire_command==0 ) begin
                                nextstate = idle; end
                            else begin 
                                if(single_previous==0) begin             
                                for(i=current_bullet; i>0; i=i-1) begin
                                    if(overheat_sensor==1) begin nextstate = overheat; single_previous=0; end
                                    else if(current_bullet==0) begin nextstate = reload; single_previous=0; end
                                    else if (current_bullet==0 & spare_magazine==0) begin nextstate = downfall; end
                                    else begin
                                    fire_trigger=1; #5; fire_trigger=0; #5; single_previous=single_previous+1; current_bullet=current_bullet-1; 
                                    if(overheat_sensor==1) begin nextstate = overheat; single_previous=0; end
                                    else if(current_bullet==0) begin nextstate = reload; single_previous=0; end  
                                    else if (current_bullet==0 & spare_magazine==0) begin nextstate = downfall; end
                                 end end
                                
                                end
                                if(fire_command==0) begin nextstate <= idle; single_previous=0;end
                                else if(overheat_sensor==1) begin nextstate = overheat; single_previous=0; end
                                else if(current_bullet==0 & spare_magazine!=0) begin nextstate = reload; single_previous=0; end
                                else if (current_bullet==0 & spare_magazine==0) begin nextstate = downfall; end
                                else begin nextstate = shoot_auto; single_previous=0; end
                            end
                        end
                    end
        shoot_single: if(overheat_sensor==1) begin
                        nextstate = overheat; #100; end
                    else begin
                        if(current_bullet==0 & spare_magazine==0) begin
                            nextstate = downfall; end
                        else if(current_bullet==0 & spare_magazine!=0) begin
                            nextstate = reload;  end
                        else begin
                            if(is_enemy==0 | target_locked==0 | fire_command==0 ) begin
                                nextstate = idle; end
                            else begin
                                if(single_previous==0) begin             
                                fire_trigger=1; #5; fire_trigger=0; #5; single_previous=single_previous+1; current_bullet=current_bullet-1; end
                                if(overheat_sensor==1) begin nextstate = overheat; single_previous=0; end
                                else if(current_bullet==0 & spare_magazine!=0) begin nextstate = reload; single_previous=0; end
                                else if (current_bullet==0 & spare_magazine==0) begin nextstate = downfall; end
                                if(fire_command==0)begin nextstate = idle; single_previous=0;end
                                else begin nextstate = shoot_single;  end
                            end if(current_bullet!=0) begin single_previous=0; end
                        end 
                    end                     
        reload: if(spare_magazine!=0) begin 
                    #40; current_bullet=25; spare_magazine=spare_magazine-1; 
                    if(spare_magazine==0) begin criticality_alert=1; end #10;
                    if(is_enemy==1 & target_locked==1 & firing_mode==0) begin             
                        nextstate = shoot_single;  end 
                    else if(is_enemy==1 & target_locked==1 & firing_mode==1) begin
                        nextstate = shoot_auto;  end
                    else begin
                        nextstate = idle; end 
                    end 
                 else begin criticality_alert=1; end
        overheat: if(1>0) begin #100;
                    if (current_bullet==0 & spare_magazine==0) begin
                        nextstate = downfall; end
                    else if(current_bullet==0 & spare_magazine!=0) begin
                        nextstate = reload; end
                    else if(is_enemy==1 & target_locked==1 & fire_command==1 & firing_mode==0 & spare_magazine!=0) begin             
                        nextstate = shoot_single; end 
                    else if(is_enemy==1 & target_locked==1 & fire_command==1 & firing_mode==1 & spare_magazine!=0) begin
                        nextstate = shoot_auto; end
                    else begin
                        nextstate = idle; end  
                   end                       
        downfall: if (1>0) begin 
                   #100;  current_bullet=25; spare_magazine=3; 
                   if(is_enemy==1 & target_locked==1 & fire_command==1 & firing_mode==0) begin             
                    nextstate = shoot_single; end 
                else if(is_enemy==1 & target_locked==1 & fire_command==1 & firing_mode==1) begin
                    nextstate = shoot_auto; end
                   
                      
                  end  
        default: 
            nextstate <= idle; 
    endcase 
end
	

endmodule








