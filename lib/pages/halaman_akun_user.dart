import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HalamanAkunUser extends StatefulWidget {
  const HalamanAkunUser({super.key});

  @override
  State<HalamanAkunUser> createState() => _HalamanAkunUserState();
}

class _HalamanAkunUserState extends State<HalamanAkunUser> {
  FirebaseAuth auth = FirebaseAuth.instance;
  User? user;
  bool isLoading = false;
  final GlobalKey<FormState> _formNameKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _formPasswordKey = GlobalKey<FormState>();
  final TextEditingController displayName = TextEditingController();
  final TextEditingController oldPassword = TextEditingController();
  final TextEditingController newPassword = TextEditingController();
  final TextEditingController confirmationNewPassword = TextEditingController();

  @override
  void initState() {
    super.initState();
    initInstanceCurrentUser();
  }

  @override
  void dispose() {
    super.dispose();
    oldPassword.dispose();
    newPassword.dispose();
    confirmationNewPassword.dispose();
  }

  void initInstanceCurrentUser() {
    setState(() {
      user = auth.currentUser;

      if (user != null) {
        displayName.text = user!.displayName ?? "";
      }
    });
  }

  Future<void> handleChangeDisplayName() async {
    if (_formNameKey.currentState!.validate() && user != null) {
      if (displayName.text == user!.displayName) return;
      setState(() {
        isLoading = true;
      });

      try {
        await user!.updateDisplayName(displayName.text);

        user!.reload();

        setState(() {
          isLoading = false;
          initInstanceCurrentUser();
        });
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red[700],
              content: Text('Error: ${e.toString()}'),
            ),
          );
        }
        return;
      }
    }
  }

  Future<void> handleChangePassword() async {
    if (_formPasswordKey.currentState!.validate() && user != null) {
      // Check Password Baru dan Password lama tidak boleh sama
      if (newPassword.text == oldPassword.text) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red[700],
              content: Text('Password Baru dan Password Lama tidak boleh sama'),
            ),
          );
        }
        return;
      }
      // Check password Baru & KOnfirmasi Password harus sama
      if (newPassword.text != confirmationNewPassword.text) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red[700],
              content: Text('Password Baru dan Konfirmasi Password tidak sama'),
            ),
          );
        }
        return;
      }

      setState(() {
        isLoading = true;
      });

      try {
        // Re-authenticate with old password
        AuthCredential credential = EmailAuthProvider.credential(
          email: user!.email!, // Assuming email-based authentication
          password: oldPassword.text,
        );

        await user!.reauthenticateWithCredential(credential);

        // Update password
        await user!.updatePassword(newPassword.text);

        // Success message
        setState(() {
          isLoading = false;
          oldPassword.clear();
          newPassword.clear();
          confirmationNewPassword.clear();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Password updated successfully!')),
          );
        }
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red[700],
              content: Text('Error: ${e.toString()}'),
            ),
          );
        }
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final FocusNode? focus = FocusManager.instance.primaryFocus;

        if (focus != null) {
          focus.unfocus();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: Colors.white),
          title: Text("Akun Anda", style: TextStyle(color: Colors.white)),
          centerTitle: true,
        ),
        body:
            isLoading
                ? Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ubah Nama Anda',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        formName(context),
                        const SizedBox(height: 16),
                        Divider(color: Colors.grey[700]),
                        const SizedBox(height: 16),
                        const Text(
                          'Ganti Password',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        formPassword(context),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  Widget formName(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[900],
      ),
      child: Form(
        key: _formNameKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextEditing(
              controller: displayName,
              labelText: 'Nama',
              textValidator: 'Mohon isi nama dahulu',
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: handleChangeDisplayName,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text(
                'Ubah Nama',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget formPassword(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[900],
      ),
      child: Form(
        key: _formPasswordKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextEditing(
              controller: oldPassword,
              labelText: 'Password Lama',
              textValidator: 'Mohon isi Password Lama',
              obscureText: true,
            ),
            const SizedBox(height: 16),
            CustomTextEditing(
              controller: newPassword,
              labelText: 'Password Baru',
              textValidator: 'Mohon isi Password Baru',
              obscureText: true,
            ),
            const SizedBox(height: 16),
            CustomTextEditing(
              controller: confirmationNewPassword,
              labelText: 'Konfirmasi Password',
              textValidator: 'Mohon isi Konfirmasi Password',
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: handleChangePassword,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text(
                'Ubah Nama',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomTextEditing extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String textValidator;
  final bool obscureText;

  const CustomTextEditing({
    super.key,
    required this.controller,
    required this.labelText,
    required this.textValidator,
    this.obscureText = false,
  });

  @override
  State<CustomTextEditing> createState() => _CustomTextEditingState();
}

class _CustomTextEditingState extends State<CustomTextEditing> {
  late bool _obscureTextField;

  @override
  void initState() {
    super.initState();
    _obscureTextField = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureTextField,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        suffixIcon:
            widget.obscureText
                ? IconButton(
                  onPressed: () {
                    setState(() {
                      _obscureTextField = !_obscureTextField;
                    });
                  },
                  icon: Icon(
                    _obscureTextField ? Icons.visibility_off : Icons.visibility,
                  ),
                )
                : null,
        labelText: widget.labelText,
        labelStyle: const TextStyle(color: Colors.white),
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return widget.textValidator;
        }

        if (widget.obscureText) {
          final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*\d)[A-Za-z\d]+$');

          if (!passwordRegex.hasMatch(value)) {
            return "Hanya Huruf Besar, Huruf Kecil & Angka diperbolehkan.";
          }

          if (value.length < 8) {
            return "${widget.labelText} kurang dari 8 karakter.";
          }
        }

        return null;
      },
    );
  }
}
