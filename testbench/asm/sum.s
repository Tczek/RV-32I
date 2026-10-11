Compute sum = 1+2+3+4+5 = 15
# Register usage:
#   x1 = loop counter (i), starts at 1
#   x2 = accumulator (sum), starts at 0
#   x3 = limit (6)
#   x4 = base address for storing result (0)

        addi x1, x0, 1       # i = 1
        addi x2, x0, 0       # sum = 0
        addi x3, x0, 6       # limit = 6

loop:   bge  x1, x3, done    # if i >= 6 goto done
        add  x2, x2, x1      # sum += i
        addi x1, x1, 1       # i++
        jal  x0, loop        # goto loop (x0 discards link)

done:   sw   x2, 0(x0)       # mem[0] = sum (= 15)
        jal  x0, done        # halt (infinite loop)