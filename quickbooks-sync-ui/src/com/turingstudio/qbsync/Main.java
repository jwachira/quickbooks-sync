package com.turingstudio.qbsync;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.InputStream;
import java.io.IOException;
import java.net.URL;

import java.util.ArrayList;
import org.jruby.Ruby;
import org.jruby.RubyInstanceConfig;
import org.jruby.javasupport.JavaEmbedUtils;

public class Main
{
  public static void main(String[] args) throws Exception
  {
    RubyInstanceConfig config = new RubyInstanceConfig();
    config.setArgv(args);
    Ruby runtime = JavaEmbedUtils.initialize(new ArrayList(0), config);
    String requirePath = getResource("jar_start.rb");
    runtime.evalScriptlet("require '" + requirePath + "'");
  }

  public static String getResource(String path) {
      return Main.class.getClassLoader().getResource(path).toString();
  }

}
