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

proc writeExceptionToFile(e: ref Exception): void =
  let f = open("shiori_proxy_error.log", fmAppend)
  f.writeLine(e.msg)
  # f.writeLine(e.stackTrace())
  f.close()

proc loadConfig(): void =
    let configFile = newFileStream("shiori_proxy.yml")
    load(configFile, config)
    configFile.close()

proc openShioriProcess(): void =
    try:
      shioriProcess = startProcess(config.command[0], ".", config.command[1..^1], options = {poDemon})
    except Exception as e:
      writeExceptionToFile(e)
      raise e
    shioriStdin = shioriProcess.inputStream
    shioriStdout = shioriProcess.outputStream

shioriLoadCallback = proc (dirpath: string): bool =
    loadConfig()
    openShioriProcess()

    shioriStdin.writeLine("LOAD SHIORIPROXY/1.0")
    shioriStdin.writeLine(dirpath)
    shioriStdin.flush()
    let value = shioriStdout.readLine()
    value == "1"

shioriRequestCallback = proc (requestStr: string): string =
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

shioriUnloadCallback = proc (): bool =
    shioriStdin.writeLine("UNLOAD SHIORIPROXY/1.0")
    shioriStdin.flush()
    let value = shioriStdout.readLine()
    shioriProcess.terminate()
    value == "1"

when appType != "lib":
    main("C:\\ssp\\ghost\\nim\\", @[
        "GET SHIORI/3.0\nCharset: UTF-8\nSender: embryo\nID: version\n\n",
        "GET SHIORI/3.0\nCharset: UTF-8\nSender: embryo\nID: OnBoot\n\n",
    ])
