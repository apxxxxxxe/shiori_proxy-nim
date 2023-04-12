import shioridll
import shiori_charset_convert
import yaml.serialization
import osproc
import streams
import strutils

type ShioriProxyConfig = object
    command: seq[string]

var config: ShioriProxyConfig
var shioriProcess: Process
var shioriStdin: Stream
var shioriStdout: Stream

proc writeToFile(msg: string): void =
  let f = open("shiori_proxy.log", fmAppend)
  f.writeLine(msg)
  f.close()

proc loadConfig(): void =
    try:
      let configFile = newFileStream("shiori_proxy.yml")
      load(configFile, config)
      configFile.close()
    except Exception as e:
      writeToFile(e.msg)
      raise e

proc openShioriProcess(): void =
    try:
      shioriProcess = startProcess(config.command[0], ".", config.command[1..^1], options = {poDemon})
    except Exception as e:
      writeToFile(e.msg)
      raise e
    shioriStdin = shioriProcess.inputStream
    shioriStdout = shioriProcess.outputStream

shioriLoadCallback = proc (dirpath: string): bool =
    try:
      writeToFile("load")
      loadConfig()
      openShioriProcess()

      shioriStdin.writeLine("LOAD SHIORIPROXY/1.0")
      shioriStdin.writeLine(dirpath)
      shioriStdin.flush()
      let value = shioriStdout.readLine()
      value == "1"
    except Exception as e:
      writeToFile(e.msg)
      raise e

shioriRequestCallback = proc (requestStr: string): string =
    try:
      writeToFile("request")
      shioriStdin.writeLine("REQUEST SHIORIPROXY/1.0")
      shioriStdin.write(requestStr)
      shioriStdin.flush()
      var line: string = ""
      var lines: seq[string] = @[]
      while shioriStdout.readLine(line):
          lines.add(line)
          if line.len() == 0:
              break
      lines.join("\n")
    except Exception as e:
      writeToFile(e.msg)
      raise e

shioriUnloadCallback = proc (): bool =
    try:
      writeToFile("unload")
      shioriStdin.writeLine("UNLOAD SHIORIPROXY/1.0")
      shioriStdin.flush()
      let value = shioriStdout.readLine()
      shioriProcess.terminate()
      value == "1"
    except Exception as e:
      writeToFile(e.msg)
      raise e

when appType != "lib":
    main("C:\\ssp\\ghost\\nim\\", @[
        "GET SHIORI/3.0\nCharset: UTF-8\nSender: embryo\nID: version\n\n",
        "GET SHIORI/3.0\nCharset: UTF-8\nSender: embryo\nID: OnBoot\n\n",
    ])
