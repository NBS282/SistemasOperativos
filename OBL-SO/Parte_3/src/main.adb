with Ada.Text_IO;                  use Ada.Text_IO;
with Ada.Integer_Text_IO;          use Ada.Integer_Text_IO;
with Ada.Synchronous_Task_Control; use Ada.Synchronous_Task_Control;

procedure Main is
   -- Constantes de instrucciones
   LOAD      : constant Integer := 0;
   STORE     : constant Integer := 1;
   ADD       : constant Integer := 2;
   SUB       : constant Integer := 3;
   BRCPU     : constant Integer := 4;
   STOP      : constant Integer := 5;
   SEMINIT   : constant Integer := 6;
   SEMWAIT   : constant Integer := 7;
   SEMSIGNAL : constant Integer := 8;
   PRINT     : constant Integer := 9;

   -- Memoria
   type Memory_Array is array (0 .. 127) of Integer;
   Memory : Memory_Array := (others => 0);

   -- Semáforo
   protected type Semaphore is
      entry Wait;
      entry Signal;
      entry Init (Val : Integer);
   private
      Count : Integer := 0;
   end Semaphore;

   protected body Semaphore is
      entry Wait when Count > 0 is
      begin
         Count := Count - 1;
      end Wait;

      entry Signal when True is
      begin
         Count := Count + 1;
      end Signal;

      entry Init (Val : Integer) when True is
      begin
         Count := Val;
      end Init;
   end Semaphore;

   Shared_Memory_Mutex : Semaphore;
   Semaphores          : array (0 .. 16) of Semaphore;


   -- Memoria compartida
   protected type Shared_Memory is
      procedure Write (Address : Integer; Value : Integer);
      procedure Read (Address : Integer; Value : out Integer);
   private
      Memory : Memory_Array := (others => 0);
   end Shared_Memory;

   protected body Shared_Memory is
      procedure Write (Address : Integer; Value : Integer) is
      begin
         if Address in Memory'Range then
            Memory (Address) := Value;
            Put_Line
              ("[Memoria] Escribiendo " & Integer'Image (Value) &
                 " en posición " & Integer'Image (Address));
         else
            Put_Line ("[Memoria] Error: Dirección fuera de rango");
         end if;
      end Write;

      procedure Read (Address : Integer; Value : out Integer) is
      begin
         if Address in Memory'Range then
            Value := Memory (Address);
            Put_Line
              ("[Memoria] Leyendo " & Integer'Image (Value) &
                 " desde posición " & Integer'Image (Address));
         else
            Put_Line ("[Memoria] Error: Dirección fuera de rango");
            Value := 0;
         end if;
      end Read;
   end Shared_Memory;

   Shared_Memory_Task : Shared_Memory;

   -- CPU
   task type CPU (ID : Integer; Start_IP : Integer) is
      entry Start;
   end CPU;

   task body CPU is
      Accumulator : Integer := 0;
      IP          : Integer := Start_IP;
      Current_Op  : Integer;
   begin
      Put_Line ("[CPU " & Integer'Image (ID) & "] Iniciando...");

      accept Start do
         null;
      end Start;

      loop
         Shared_Memory_Task.Read (IP, Current_Op);

         case Current_Op is
            when SEMWAIT =>
               declare
                  Semaphore_ID : Integer;
               begin
                  Put_Line
                    ("[CPU " & Integer'Image (ID) & "] Ejecutando SEMWAIT");
                  IP := IP + 1;
                  Shared_Memory_Task.Read (IP, Semaphore_ID);
                  Put_Line
                    ("[CPU " & Integer'Image (ID) & "] Esperando semáforo " &
                       Integer'Image (Semaphore_ID));
                  Semaphores (Semaphore_ID).Wait;
               end;

            when SEMSIGNAL =>
               declare
                  Semaphore_ID : Integer;
               begin
                  Put_Line
                    ("[CPU " & Integer'Image (ID) & "] Ejecutando SEMSIGNAL");
                  IP := IP + 1;
                  Shared_Memory_Task.Read (IP, Semaphore_ID);
                  Semaphores (Semaphore_ID).Signal;
                  Put_Line
                    ("[CPU " & Integer'Image (ID) & "] Liberado semáforo " &
                       Integer'Image (Semaphore_ID));
               end;

            when LOAD =>
               declare
                  Address : Integer;
               begin
                  Put_Line
                    ("[CPU " & Integer'Image (ID) & "] Ejecutando LOAD");
                  IP := IP + 1;
                  Shared_Memory_Task.Read (IP, Address);
                  Shared_Memory_Task.Read (Address, Accumulator);
                  Put_Line
                    ("[CPU " & Integer'Image (ID) &
                       "] Cargado en acumulador: " &
                       Integer'Image (Accumulator));
               end;

            when ADD =>
               declare
                  Address : Integer;
                  Value   : Integer;
               begin
                  Put_Line ("[CPU " & Integer'Image (ID) & "] Ejecutando ADD");
                  IP := IP + 1;
                  Shared_Memory_Task.Read (IP, Address);
                  Shared_Memory_Task.Read (Address, Value);
                  Accumulator := Accumulator + Value;
                  Put_Line
                    ("[CPU " & Integer'Image (ID) &
                       "] Resultado acumulador tras suma: " &
                       Integer'Image (Accumulator));
               end;
            when SUB =>
               declare
                  Address : Integer;
                  Value   : Integer;
               begin
                  Put_Line ("[CPU " & Integer'Image (ID) & "] Ejecutando SUB");
                  IP := IP + 1;
                  Shared_Memory_Task.Read (IP, Address);
                  Shared_Memory_Task.Read (Address, Value);
                  Accumulator := Accumulator - Value;
                  Put_Line
                    ("[CPU " & Integer'Image (ID) &
                       "] Resultado acumulador tras resta: " &
                       Integer'Image (Accumulator));
               end;

            when BRCPU =>
               declare
                  Target_CPU : Integer;
                  Target_Adress : Integer;
               begin
                  Put_Line
                    ("[CPU " & Integer'Image (ID) & "] Ejecutando BRCPU");
                  IP := IP + 1;
                  Shared_Memory_Task.Read (IP, Target_CPU);
                  IP := IP + 1;
                  Shared_Memory_Task.Read (IP, Target_Adress);

                  IP := Target_Adress;
                  if ID /= Target_CPU then
                     Put_Line
                       ("[CPU " & Integer'Image (ID) &
                          "] Saltando instrucciones para otro CPU");
                     exit; -- Salir de la ejecución actual.
                  end if;
               end;

            when SEMINIT =>
               declare
                  Semaphore_ID : Integer;
                  Init_Value   : Integer;
               begin
                  Put_Line
                    ("[CPU " & Integer'Image (ID) & "] Ejecutando SEMINIT");
                  IP := IP + 1;
                  Shared_Memory_Task.Read (IP, Semaphore_ID);
                  IP := IP + 1;
                  Shared_Memory_Task.Read (IP, Init_Value);
                  Semaphores (Semaphore_ID).Init (Init_Value);
                  Put_Line
                    ("[CPU " & Integer'Image (ID) & "] Semáforo " &
                       Integer'Image (Semaphore_ID) &
                       " inicializado con valor " & Integer'Image (Init_Value));
               end;

            when STORE =>
               declare
                  Address : Integer;
               begin
                  Put_Line
                    ("[CPU " & Integer'Image (ID) & "] Ejecutando STORE");
                  IP := IP + 1;
                  Shared_Memory_Task.Read (IP, Address);
                  Shared_Memory_Task.Write (Address, Accumulator);
                  Put_Line
                    ("[CPU " & Integer'Image (ID) & "] Guardado " &
                       Integer'Image (Accumulator) & " en posición " &
                       Integer'Image (Address));
               end;

            when PRINT =>
               declare
                  Address : Integer;
                  Value   : Integer;
               begin
                  IP := IP + 1;
                  Shared_Memory_Task.Read (IP, Address);
                  Shared_Memory_Task.Read (Address, Value);
                  Put_Line
                    ("[CPU " & Integer'Image (ID) & "] Imprimiendo resultado final : " & Integer'Image (Value));
               end;

            when STOP =>
               Put_Line ("[CPU " & Integer'Image (ID) & "] STOP ejecutado.");
               exit;

               when others =>
               Put_Line
                 ("[CPU " & Integer'Image (ID) & "] Instrucción no válida.");
               exit;
         end case;

         IP := IP + 1;
      end loop;
   end CPU;

begin
   -- Inicializar semáforos

   Semaphores (1).Init (1);  -- Semáforo para sincronizar CPU
   Semaphores (0).Init (-1); -- Semáforo para sincronizar la impresión final

   -- Valores iniciales en memoria
   Shared_Memory_Task.Write (100, 8);    -- Valor inicial
   Shared_Memory_Task.Write (101, 13);   -- Valor para CPU 0
   Shared_Memory_Task.Write (102, 27);   -- Valor para CPU 1

   -- Instrucciones CPU 0
   Shared_Memory_Task.Write (0, SEMWAIT);
   Shared_Memory_Task.Write (1, 1);
   Shared_Memory_Task.Write (2, LOAD);
   Shared_Memory_Task.Write (3, 100);
   Shared_Memory_Task.Write (4, ADD);
   Shared_Memory_Task.Write (5, 101);
   Shared_Memory_Task.Write (6, STORE);
   Shared_Memory_Task.Write (7, 100);
   Shared_Memory_Task.Write (8, SEMSIGNAL);
   Shared_Memory_Task.Write (9, 1);
   Shared_Memory_Task.Write (10, SEMSIGNAL);
   Shared_Memory_Task.Write (11, 0);
   Shared_Memory_Task.Write (12, STOP);

   -- Instrucciones CPU 1
   Shared_Memory_Task.Write (20, SEMWAIT);
   Shared_Memory_Task.Write (21, 1);
   Shared_Memory_Task.Write (22, LOAD);
   Shared_Memory_Task.Write (23, 100);
   Shared_Memory_Task.Write (24, ADD);
   Shared_Memory_Task.Write (25, 102);
   Shared_Memory_Task.Write (26, STORE);
   Shared_Memory_Task.Write (27, 100);
   Shared_Memory_Task.Write (28, SEMSIGNAL);
   Shared_Memory_Task.Write (29, 1);
   Shared_Memory_Task.Write (30, SEMSIGNAL);
   Shared_Memory_Task.Write (31, 0);
   Shared_Memory_Task.Write (32, BRCPU);
   Shared_Memory_Task.Write (33, 1);
   Shared_Memory_Task.Write (34, 49);

   -- Imprimo resultado
   Shared_Memory_Task.Write (50, SEMWAIT);
   Shared_Memory_Task.Write (51, 0);
   Shared_Memory_Task.Write (52, PRINT);
   Shared_Memory_Task.Write (53, 100);
   Shared_Memory_Task.Write (54, STOP);

   declare
      CPU_0 : CPU (0, 0);
      CPU_1 : CPU (1, 20);

   begin
      CPU_0.Start;
      CPU_1.Start;

   end;
end Main;
