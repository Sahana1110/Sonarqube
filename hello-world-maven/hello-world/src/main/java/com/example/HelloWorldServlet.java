package com.example;

import java.io.IOException;
import javax.servlet.Servlet;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

// @WebServlet annotation automatically maps the servlet to the /hello URL
//@WebServlet("/hello")
public class HelloWorldServlet extends HttpServlet {

    // This method handles HTTP GET requests
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        // Set the content type for the response
        response.setContentType("text/html");
        
        // Write the response message to the client (a simple Hello World message)
        response.getWriter().println("<h1>Hello, World!</h1>");
    }
}
