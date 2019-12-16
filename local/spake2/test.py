import hkdf

execfile('/projects/magic_wormhole/lib/spake2/spake2/spake2.py')

a = SPAKE2_Symmetric('password')
a_out = a.start()
print('The outbound message of a is ' + bytes_to_str(a_out))

# b = SPAKE2_Symmetric('password')
# b_out = b.start()
# print('The outbound message of b is ' + bytes_to_str(b_out))

received = [83, 215, 70, 84, 27, 85, 9, 112, 5, 126, 190, 5, 150, 113, 4, 189, 112, 79, 228, 191, 135, 161, 79, 121, 72, 18, 145, 109, 237, 38, 70, 118, 10]
a_key = a.finish(''.join(map(chr, received)))
print('The key of a is ' + bytes_to_str(a_key))

# b_key = b.finish(a_out)
# print('The key of b is ' + bytes_to_str(b_key))
