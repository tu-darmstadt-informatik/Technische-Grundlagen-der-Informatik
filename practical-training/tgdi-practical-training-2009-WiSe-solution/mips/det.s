#TGDI-Praktikum WS 09/10
#Berechnung der Determinante einer 3x3 bzw. 4x4 Matrix

.data

dim:
.word 3
#.word 4

matrix:
#3x3-Matrix
.word 3, 4, 5, 9, 4, 9, 1, 2, 2
#.word 1, 2, 3, 4, 5, 6, 7, 8, 9
#4x4-Matrix
#.word 3, 4, 5, 9, 4, 9, 1, 2, 2, 1, 3, 5, 7, 9, 3, 5
#.word 1, 2, 3, 4, 5, 6, 7, 8, 9, 1, 2, 3, 4, 5, 6, 7
	 
det:	.asciiz "Die Determinante ist: "
###############################################################################
	 
.text

main:
###################################
###################################
#Hier soll das Programm stehen
#Das Ergebnis muss am Ende in $s6 stehen.

#
#	(c) Jana Becher, Ulf Gebhardt 2010
#		
#		Dieses Programm wurde in Java geschrieben und dann
#		händisch übersetzt. Der Java-Algorithmus wird beigelegt.
#
#		Dieses Programm kann von nXn Matrizen die Determinante bestimmen,
#		Allerdings sollte n <= 2^31 sein und die enthaltenen Zahlen in der Matrix
#		sollten folgende bedingungen erfüllen: max(a1*a2*...*an) <= 2^31, wobei a1
#		bis an beliebige Zahlen aus der Matrix sind.
#


				lw $a0, dim     								#load dimension
				la $a1, matrix  								#load matrix-startadress
				jal calcdet										#calc determinante
				addi $s6, $v0, 0								#write result to $s6
				j ende											#ende

#pow(integer,integer) = integer
#
#$a0 = number;
#$a1 = exp;
#$v0 = number^exp
#Comment:
#Java: Math.pow
#keep it withoin 32bit -> using mul
#
pow:			addi $t0, $0, 0 								#load 0 in $t0
				ble $a1, $t0, powrecdone						#$a1 <= 0
				sw $ra, 0($sp)									#sichere $ra
				addi $sp, $sp, 4								#stackpointer + 1
				addi $a1, $a1, -1								#$a1 -= 1
				jal pow											#jump in pow
				addi $sp, $sp -4								#stackpointer - 1
				lw $ra, 0($sp)									#sichere $ra zurück
				mul $v0,$a0, $v0								#$v0 = number($a0) * pow($v0)
				jr $ra											#jumpback

				powrecdone: addi $v0, $0, 1						#result = 1
						 	jr $ra								#jumpback

#calcnewmatrix(integer,integer,address) = address, size
#
#$a0 = pos in Matrix
#$a1 = size of matrix
#$a2 = address of matrix
#$v0 = address of new matrix (on stack)
#$v1 = size of matrix on stack (negative -> add to $sp)
#Comment:
#new matrix lives on Stack, but stackpointer is not increased - do it if you need the object
#
calcnewmatrix:	#create new matrix with (size-1)*(size-1) and store size in $v1, address =$sp
				addi $t0, $a1, -1   							#$t0=  size-1
				mul $t0, $t0, $t0   							#$t0= (size-1)(size-1)
				addi $t1, $0, 4									#$t1=  bytes in 1 word
				mul $t0, $t0, $t1								#$t0= bytesperword*arraysize
				addi $v1, $t0, 0								#result $v1 = $t0 = arraysize in bytes on stack

				#forA
				addi $t0, $0, 1 								#$t0=counter for forA = i starts with 1
				forA:	bge $t0, $a1, cnmjb 					#exit calcnewmatrix: cnmjb
						
						addi $t1, $0, 0							#$t1=counter for forB = j starts with 0
						forB:	bge $t1, $a1, forBDone 			#exit forB -> forA: forBDone
								
								beq $t1, $a0, forBSkip 			#if(pos == j) skip one cycle
								
								addi $t2, $t1, 0 				#tempvar $t2 = j
								blt $t2, $a0, forBCalc 			#if(j($t2) < pos($a0)) start calc
								addi $t2, $t2, -1 				#else $t2 -= 1

								forBCalc: 	addi $t7, $0, 4		#byteofset of an integer in $t7

											#oldmatrixpos
											mul $t3, $t0, $a1	#$t3=i*size
											add $t3, $t3, $t1	#$t3=i*size+j = posinmatrix
											mul $t3, $t3, $t7	#$t3=byteoffset*posinmatrix
											add $t3, $t3, $a2   #$t3=matrixadress+byteoffset*posinmatrix
											
											#newmatrixoffset
											addi $t4, $t0, -1	#$t4=i-1
										 	addi $t5, $a1, -1   #$t5=size-1
											mul $t4, $t4, $t5	#$t4=(i-1)*(size-1)
										  	add $t4, $t4, $t2	#$t4=(i-1)*(size-1) + j(-1 if pos is already skipped) =posinmatrix
											mul $t4, $t4, $t7	#$t4=byteoffset*posinmatrix
											add $t4, $t4, $sp   #$t4=newmatrixadress($sp)+byteoffset*posinmatrix

											#load value of old matrix
											lw $t5, 0($t3)		#$t5=oldmatrix[$t3]
											
											#store word in new matrix
											sw $t5, 0($t4)		#newmatrix[$t4] = $t5

								forBSkip:	#skip forB Calculation needed for j==pos
							 	#forB: j++ and forjumpback
								addi $t1, $t1, 1				#j++
								j forB							#forB Jumpback
	
						forBDone: 								#Dummy to jump out of ForB and continue with ForA

						#forA: i++ and forjumpback
						addi $t0, $t0,1 						#i++
						j forA									#forA Jumpback

				#calcnewmatrixjumpback
				cnmjb:	addi $v0, $sp, 0						#result=$sp=newmatrixadress #add $v0 to $sp to keep dataobject
						jr $ra									#jump back

#calcdet(integer,address) = integer
#
#$a0 = size of matrix(dimension)
#$a1 = address of matrix
#$v0 = determinante of matrix
#Comment:
#size is in most cases the dimension of the matrix not the actual size, which is (dim*dim)
calcdet:		#Rec-Anchor and Result
				addi $t0, $0, 1									#load 1 in $t0
				beq $a0, $t0, recanchor							#check size 
				addi $t5, $0, 0									#set result to 0						
				
				#for1
				addi $t0, $0, 0									#countervar $t0 for for1 -> countervar=i
				for1:	bge $t0, $a0, cdjb						#if i >= size -> cdjb #Rescursion Anchor
		
						#sichere vars			
						sw $ra, 0($sp)							#sichere $ra
						sw $t5,	4($sp)							#sichere result
						sw $t0, 8($sp)							#sichere for-counter
						sw $a0, 12($sp)							#sichere param0
						sw $a1, 16($sp)							#sichere param1
						addi $sp, $sp, 20						#stackpointer - 5													#stack +5

						#pow(-1,forcounter) -> t2
						addi $a0, $0, -1						#number = -1
						add	 $a1, $0, $t0						#exp = for-counter 
						jal pow									#calc pow

						#sichere result
						sw $v0, 0($sp)							#sichere result nach stack
						addi $sp, $sp, 4						#stackpointer - 1													#stack +1

						#CalcNewMatrix
						lw $t0, -16($sp)						#load for-counter=i			
						addi $a0, $t0, 0						#pos = i
						lw $t7, -12($sp)						#load $a0=size
						addi $a1, $t7, 0						#size
						lw $t7, -8($sp)							#load $a1=matrixaddress
						addi $a2, $t7, 0						#matrix
						jal calcnewmatrix						#calcnewmatrix -> newmatrix=$v0
						addi $t6, $sp, 0						#$t6 = store $sp before matrix and size is added! - makes it simple
						add $sp, $sp, $v1						#Matrix is on Stack now, keep it by increasing stackpointer			#stack +$v1
						sw $v1, 0($sp)							#Store size of Matrix@Stack to delete it afterwards
						sw $t6, 4($sp)							#Store old $sp					
						addi $sp, $sp, 8						#1word on Stack reserved											#stack +2

						#CalcDet - Recursion ($t3)
						lw $t7, -12($t6)						#load $a0=size #Oldstackpointer $t6
						addi $a0, $t7, -1						#size -1
						addi $a1, $v0, 0						#matrixaddress from calcnewmatrix
						jal calcdet								#calcdet of new matrix
						addi $t3, $v0, 0						#Save result from calcdet in $t3
						
						#restore vars/cleanup
						addi $sp, $sp, -4						#1word - stored sp													#stack -1
						lw $t7, 0($sp)							#load old sp
						addi $sp, $t7, 0						#free memory used for matrix and matrixsize							#stack -$v1 -1
						addi $sp, $sp, -24						#stackpointer - 6													#stack -6
						lw $ra, 0($sp)							#sichere $ra
						lw $t5,	4($sp)							#sichere result
						lw $t0, 8($sp)							#sichere for-counter
						lw $a0, 12($sp)							#sichere param0
						lw $a1, 16($sp)							#sichere param1
						lw $t1, 20($sp)    						#result aus pow

						#Get Matrix@pos i
						addi $t7, $0, 4							#bytesize of word -> $t7	
						mul $t7, $t0, $t7						#matrixposcalc: i*byteoffset
						add $t7, $t7, $a1						#get actual matrixpos
						lw $t2, 0($t7)							#loadmatrix content @ pos forcounter

						#calc result #tempvar = $t7
						mul $t7, $t1, $t2   					#pow*matrix@posi
						mul $t7, $t7, $t3						#pow*matrixpos@posi*submatrix
						add $t5, $t5, $t7 						#add to result

						#for: i++ and forjumpback
						addi $t0,$t0, 1							# +1 to counter
						j for1									#jump to for again

				#cdjb = calcdetjumpback
				cdjb:	addi $v0, $t5, 0						#set result 
						jr $ra									#jump back 

				recanchor:	lw $v0, 0($a1) 						#return matrix[0]
							jr $ra								#jump back
###################################
###################################

ende:
#Ausgabe

la $a0 det
li $v0 4
syscall

move $a0, $s6
li $v0, 1
syscall

###################################
#Ende
li $v0, 10
syscall
