execfile('spake2/ed25519_basic.py')
execfile('spake2/groups.py')

class _Ed25519Group:
    def random_scalar(self, entropy_f):
        return random_scalar(entropy_f)
    def scalar_to_bytes(self, i):
        return scalar_to_bytes(i)
    def bytes_to_scalar(self, b):
        return bytes_to_scalar(b)
    def password_to_scalar(self, pw):
        return password_to_scalar(pw, self.scalar_size_bytes, self.order())
    def arbitrary_element(self, seed):
        return arbitrary_element(seed)
    def bytes_to_element(self, b):
        return bytes_to_element(b)
    def order(self):
        return L

Ed25519Group = _Ed25519Group()
Ed25519Group.Base = Base
Ed25519Group.Zero = Zero
Ed25519Group.scalar_size_bytes = 32
Ed25519Group.element_size_bytes = 32
