package com.goalflow.api.dto;

public class RegisterRequest {
    private String email;
    private String password;
    private String nickname;

    public RegisterRequest() {}

    public RegisterRequest(String email, String password, String nickname) {
        this.email = email;
        this.password = password;
        this.nickname = nickname;
    }

    public static RegisterRequestBuilder builder() {
        return new RegisterRequestBuilder();
    }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }
    public String getNickname() { return nickname; }
    public void setNickname(String nickname) { this.nickname = nickname; }

    public static class RegisterRequestBuilder {
        private String email;
        private String password;
        private String nickname;

        public RegisterRequestBuilder email(String email) { this.email = email; return this; }
        public RegisterRequestBuilder password(String password) { this.password = password; return this; }
        public RegisterRequestBuilder nickname(String nickname) { this.nickname = nickname; return this; }
        public RegisterRequest build() { return new RegisterRequest(email, password, nickname); }
    }
}
